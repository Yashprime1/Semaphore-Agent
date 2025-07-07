const https = require('https');
const utils = require("util");
const { Agent } = require("https");
const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");
const { ApplicationAutoScalingClient, DescribeScalableTargetsCommand, RegisterScalableTargetCommand } = require("@aws-sdk/client-application-auto-scaling");
const { ECSClient, UpdateServiceCommand, DescribeServicesCommand } = require("@aws-sdk/client-ecs");
const { CloudWatchClient, PutMetricDataCommand } = require("@aws-sdk/client-cloudwatch");
const { NodeHttpHandler } = require("@aws-sdk/node-http-handler");

const CONNECTION_TIMEOUT = 1000;
const SOCKET_TIMEOUT = 1000;

function getAgentTypeToken(ssmClient, tokenParameterName) {
  const params = {
    Name: tokenParameterName,
    WithDecryption: true
  };

  console.log("Fetching agent type token...");

  return new Promise(function(resolve, reject) {
    const command = new GetParameterCommand(params);
    ssmClient.send(command, function(err, data) {
      if (err) {
        console.log("Error getting agent type registration token parameter: ", err);
        reject(err);
      } else {
        resolve(data.Parameter.Value);
      }
    });
  });
}

function buildMetricData(stackName, metrics) {
  let metricData = [];

  Object.keys(metrics.jobs).forEach(state => {
    metricData.push({
      MetricName: `JobCount`,
      Value: metrics.jobs[state],
      Unit: "Count",
      Timestamp: new Date(),
      Dimensions: [
        {Name: "StackName", Value: stackName},
        {Name: "JobState", Value: state}
      ]
    });
  });

  Object.keys(metrics.agents).forEach(state => {
    metricData.push({
      MetricName: `AgentCount`,
      Value: metrics.agents[state],
      Unit: "Count",
      Timestamp: new Date(),
      Dimensions: [
        {Name: "StackName", Value: stackName},
        {Name: "AgentState", Value: state}
      ]
    });
  });

  return metricData;
}

function publishOccupancyMetrics(cloudwatchClient, stackName, metrics) {
  const metricData = buildMetricData(stackName, metrics)
  console.log(`Publishing metrics to CloudWatch: ${utils.inspect(metricData, {depth: 3})}`);

  return new Promise(function(resolve, reject) {
    const command = new PutMetricDataCommand({ MetricData: metricData, Namespace: "Semaphore" });
    cloudwatchClient.send(command, function(err, data) {
      if (err) {
        console.log("Error publishing metrics: ", err);
        reject(err);
      } else {
        resolve(data);
      }
    });
  });
}

function getAgentTypeMetrics(token, semaphoreEndpoint) {
  console.log("Fetching metrics from Semaphore API...");

  const options = {
    hostname: semaphoreEndpoint,
    path: "/api/v1/self_hosted_agents/metrics",
    method: 'GET',
    timeout: 1000,
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Token ${token}`,
      "Agent": "aws-dynamic-scaler"
    }
  }

  return new Promise((resolve, reject) => {
    let data = '';
    const request = https.request(options, response => {
      if (response.statusCode !== 200) {
        reject(`Request to get occupancy got ${response.statusCode}`);
        return;
      }

      response.on('data', function (chunk) {
        data += chunk;
      });

      response.on('end', function () {
        resolve(JSON.parse(data));
      });
    });

    request.on('error', error => reject(error))
    request.on('timeout', () => request.destroy())
    request.setTimeout(1000);
    request.end();
  })
}

function determineNewSize(totalJobs, min, max, overprovisionStrategy, overprovisionFactor) {
  /**
   * If the number of total jobs is below the minimum size for the stack,
   * we don't apply any overprovisioning strategies.
   */
  if (totalJobs < min) {
    return min
  }

  let newSize = totalJobs;
  switch (overprovisionStrategy) {
    case "none":
      console.log(`No overprovision strategy configured - new size is ${newSize}`);
      break
    case "number":
      newSize += overprovisionFactor;
      console.log(`Overprovision strategy ${overprovisionStrategy} configured (${overprovisionFactor}) - new desired size is ${newSize}`);
      break
    case "percentage":
      newSize += Math.ceil((totalJobs * overprovisionFactor) / 100);
      console.log(`Overprovision strategy ${overprovisionStrategy} configured (${overprovisionFactor}) - new desired size is ${newSize}`);
      break
  }

  if (newSize > max) {
    console.log(`New desired size is ${newSize}, but maximum is ${max} - new size is ${max}`);
    return max;
  }

  return newSize;
}

const scaleServiceIfNeeded = async (ecsClient, clusterName, serviceName, occupancy, scalingConfig, service, overprovisionStrategy, overprovisionFactor) => {
  const totalJobs = Object.keys(occupancy).reduce((count, state) => count + occupancy[state], 0);

  console.log(`Agent type occupancy: `, occupancy);
  console.log(`Current ECS service state: `, service);
  console.log(`Current scaling configuration: `, scalingConfig);

  const newSize = determineNewSize(totalJobs, scalingConfig.minCapacity, scalingConfig.maxCapacity, overprovisionStrategy, overprovisionFactor);
  if (newSize > service.desiredCount) {
    await updateEcsServiceDesiredCount(ecsClient, clusterName, serviceName, newSize);
    console.log(`Successfully scaled up ECS service '${serviceName}' to ${newSize}.`);
  }  else if (newSize < service.desiredCount) {
    await updateEcsServiceDesiredCount(ecsClient, clusterName, serviceName, newSize);
    console.log(`Successfully scaled down ECS service '${serviceName}' from ${service.desiredCount} to ${newSize}.`);
  }  
  else {
    console.log(`No need to scale up ECS service '${serviceName}'. Current: ${service.desiredCount}, Calculated: ${newSize}`);
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function epochSeconds() {
  return Math.round(Date.now() / 1000);
}
// For ECS -
function describeEcsService(ecsClient, clusterName, serviceName) {
  console.log(`Describing ECS service '${serviceName}' in cluster '${clusterName}'...`);

  const params = {
    cluster: clusterName,
    services: [serviceName]
  };

  return new Promise(function(resolve, reject) {
    const command = new DescribeServicesCommand(params);
    ecsClient.send(command, function(err, data) {
      if (err) {
        console.log("Error describing ECS service: ", err);
        reject(err);
      } else {
        let services = data.services;
        if (services.length === 0) {
          reject(`Could not find ECS service '${serviceName}' in cluster '${clusterName}'`);
        } else {
          let service = services[0];
          resolve({
            serviceName: service.serviceName,
            clusterArn: service.clusterArn,
            desiredCount: service.desiredCount,
            runningCount: service.runningCount,
            pendingCount: service.pendingCount,
            status: service.status
          });
        }
      }
    });
  });
}

function describeEcsApplicationAutoscaling(appAutoScalingClient, clusterName, serviceName) {
  console.log(`Describing ECS application autoscaling for service '${serviceName}' in cluster '${clusterName}'...`);

  const resourceId = `service/${clusterName}/${serviceName}`;
  
  const params = {
    ServiceNamespace: 'ecs',
    ResourceIds: [resourceId],
    ScalableDimension: 'ecs:service:DesiredCount'
  };

  return new Promise(function(resolve, reject) {
    const command = new DescribeScalableTargetsCommand(params);
    appAutoScalingClient.send(command, function(err, data) {
      if (err) {
        console.log("Error describing ECS application autoscaling: ", err);
        reject(err);
      } else {
        let scalableTargets = data.ScalableTargets;
        if (scalableTargets.length === 0) {
          reject(`Could not find application autoscaling for service '${serviceName}' in cluster '${clusterName}'`);
        } else {
          let target = scalableTargets[0];
          resolve({
            serviceName: serviceName,
            clusterName: clusterName,
            resourceId: target.ResourceId,
            minCapacity: target.MinCapacity,
            maxCapacity: target.MaxCapacity,
            roleArn: target.RoleARN,
            creationTime: target.CreationTime
          });
        }
      }
    });
  });
}

function updateEcsServiceDesiredCount(ecsClient, clusterName, serviceName, desiredCount) {
  console.log(`Scaling ECS service '${serviceName}' in cluster '${clusterName}' to ${desiredCount}...`);

  const params = {
    cluster: clusterName,
    service: serviceName,
    desiredCount: desiredCount
  };

  return new Promise(function(resolve, reject) {
    const command = new UpdateServiceCommand(params);
    ecsClient.send(command, function(err, data) {
      if (err) {
        console.log("Error scaling ECS service: ", err);
        reject(err);
      } else {
        resolve(data);
      }
    });
  });
}

const tick = async (agentTypeToken, stackName, clusterName, serviceName, ecsClient, appAutoScalingClient, cloudwatchClient, semaphoreEndpoint, overprovisionStrategy, overprovisionFactor) => {
  try {
    const metrics = await getAgentTypeMetrics(agentTypeToken, semaphoreEndpoint);
    await publishOccupancyMetrics(cloudwatchClient, stackName, metrics);
    
    // Get current ECS service state
    const service = await describeEcsService(ecsClient, clusterName, serviceName);
    
    // Get Application Auto Scaling configuration
    const scalingConfig = await describeEcsApplicationAutoscaling(appAutoScalingClient, clusterName, serviceName);
    
    await scaleServiceIfNeeded(ecsClient, clusterName, serviceName, metrics.jobs, scalingConfig, service, overprovisionStrategy, overprovisionFactor);
  } catch (e) {
    console.error("Error in tick execution", e);
  }
}

exports.handler = async (event, context, callback) => {
  const agentTokenParameterName = process.env.SEMAPHORE_AGENT_TOKEN_PARAMETER_NAME;
  if (!agentTokenParameterName) {
    console.error("No SEMAPHORE_AGENT_TOKEN_PARAMETER_NAME specified.")
    return {
      statusCode: 500,
      message: "error",
    };
  }

  const stackName = process.env.SEMAPHORE_AGENT_STACK_NAME;
  if (!stackName) {
    console.error("No SEMAPHORE_AGENT_STACK_NAME specified.")
    return {
      statusCode: 500,
      message: "error",
    };
  }

  const clusterName = process.env.ECS_CLUSTER_NAME;
  if (!clusterName) {
    console.error("No ECS_CLUSTER_NAME specified.")
    return {
      statusCode: 500,
      message: "error",
    };
  }

  const serviceName = process.env.ECS_SERVICE_NAME;
  if (!serviceName) {
    console.error("No ECS_SERVICE_NAME specified.")
    return {
      statusCode: 500,
      message: "error",
    };
  }

  const semaphoreEndpoint = process.env.SEMAPHORE_ENDPOINT;
  if (!semaphoreEndpoint) {
    console.error("No SEMAPHORE_ENDPOINT specified.")
    return {
      statusCode: 500,
      message: "error",
    };
  }

  const overprovisionStrategy = process.env.SEMAPHORE_AGENT_OVERPROVISION_STRATEGY;
  if (!overprovisionStrategy) {
    console.error("No SEMAPHORE_AGENT_OVERPROVISION_STRATEGY specified.")
    return {
      statusCode: 500,
      message: "error",
    };
  }

  /**
   * We know that this is valid because we validate it before deploying the stack,
   * so there's no need to validate it here again.
   */
  const overprovisionFactor = parseInt(process.env.SEMAPHORE_AGENT_OVERPROVISION_FACTOR);

  const ssmClient = new SSMClient({
    maxAttempts: 1,
    requestHandler: new NodeHttpHandler({
      connectionTimeout: CONNECTION_TIMEOUT,
      socketTimeout: SOCKET_TIMEOUT,
      httpsAgent: new Agent({
        timeout: SOCKET_TIMEOUT
      })
    }),
  });

  const cloudwatchClient = new CloudWatchClient({
    maxAttempts: 1,
    requestHandler: new NodeHttpHandler({
      connectionTimeout: CONNECTION_TIMEOUT,
      socketTimeout: SOCKET_TIMEOUT,
      httpsAgent: new Agent({
        timeout: SOCKET_TIMEOUT
      })
    }),
  });

  const ecsClient = new ECSClient({
    maxAttempts: 1,
    requestHandler: new NodeHttpHandler({
      connectionTimeout: CONNECTION_TIMEOUT,
      socketTimeout: SOCKET_TIMEOUT,
      httpsAgent: new Agent({
        timeout: SOCKET_TIMEOUT
      })
    }),
  });

  const appAutoScalingClient = new ApplicationAutoScalingClient({
    maxAttempts: 1,
    requestHandler: new NodeHttpHandler({
      connectionTimeout: CONNECTION_TIMEOUT,
      socketTimeout: SOCKET_TIMEOUT,
      httpsAgent: new Agent({
        timeout: SOCKET_TIMEOUT
      })
    }),
  });

  /**
   * The interval between ticks.
   * This is required because the smallest unit for a scheduled lambda is 1 minute.
   * So, we run a tick every 10s, exiting before the 60s lambda timeout is reached.
   */
  const interval = 10;
  const timeout = epochSeconds() + 60;
  const tickDuration = 5;
  let now = epochSeconds();

  try {
    const agentTypeToken = await getAgentTypeToken(ssmClient, agentTokenParameterName);

    while (true) {
      await tick(agentTypeToken, stackName, clusterName, serviceName, ecsClient, appAutoScalingClient, cloudwatchClient, semaphoreEndpoint, overprovisionStrategy, overprovisionFactor);

      // Check if we will hit the timeout before sleeping.
      // We include a worst-case scenario for the next tick duration (5s) here too,
      // to avoid hitting the timeout while running the next tick.
      now = epochSeconds();
      if ((now + interval + tickDuration) >= timeout) {
        break
      }

      console.log(`Sleeping ${interval}s...`);
      await sleep(interval * 1000);
    }

    return {
      statusCode: 200,
      message: "success",
    }
  } catch (e) {
    console.error("Error fetching agent type token", e);
    return {
      statusCode: 500,
      message: "error",
    }
  }
};