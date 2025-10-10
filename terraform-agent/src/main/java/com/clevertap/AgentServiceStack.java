package com.clevertap;

import java.util.HashMap;
import software.amazon.awscdk.Aws;
import software.amazon.awscdk.Stack;
import software.amazon.awscdk.StackProps;
import software.amazon.awscdk.Tags;
import software.amazon.awscdk.services.ec2.SubnetSelection;
import software.amazon.awscdk.services.ec2.SubnetType;
import software.amazon.awscdk.services.ecs.AwsLogDriver;
import software.amazon.awscdk.services.ecs.Compatibility;
import software.amazon.awscdk.services.ecs.ContainerDefinitionOptions;
import software.amazon.awscdk.services.ecs.ContainerImage;
import software.amazon.awscdk.services.ecs.FargateService;
import software.amazon.awscdk.services.ecs.LogDriver;
import software.amazon.awscdk.services.ecs.NetworkMode;
import software.amazon.awscdk.services.ecs.PropagatedTagSource;
import software.amazon.awscdk.services.ecs.Secret;
import software.amazon.awscdk.services.ecs.SplunkLogDriver;
import software.amazon.awscdk.services.ecs.SplunkLogFormat;
import software.amazon.awscdk.services.ecs.TaskDefinition;
import software.amazon.awscdk.services.ecs.TaskDefinitionProps;
import software.constructs.Construct;
import java.util.Map;

public class AgentServiceStack extends Stack {

  public AgentServiceStack(final Construct scope, final String id, final StackProps props,
      AgentServiceStackProps agentServiceStackProps) {
    super(scope, id, props);

    Map<String, String> terraformAgentContainerEnvironment = new HashMap<>();
    terraformAgentContainerEnvironment.put("TFC_AGENT_NAME", "terraform-agent");
    terraformAgentContainerEnvironment.put("TFC_AGENT_SINGLE", "true");

    TaskDefinition terraformAgentEcsTaskDefinition = new TaskDefinition(this,
        "TerraformAgentEcsTaskDefinition", TaskDefinitionProps.builder()
        .compatibility(Compatibility.FARGATE)
        .cpu(String.valueOf(256))
        .memoryMiB(String.valueOf(512))
        .networkMode(NetworkMode.AWS_VPC)
        .family(Aws.STACK_NAME)
        .build());

    Map<String, software.amazon.awscdk.services.ecs.Secret> terraformAgentContainerSecrets = new HashMap<>();
    terraformAgentContainerSecrets.put("TFC_AGENT_TOKEN",
        Secret.fromSecretsManager(agentServiceStackProps.getTcfAgentToken()));

    LogDriver taskLogDriver;
    // ToDo: Switch between AwsLogDriver and SplunkLogDriver
    // depending on which environment (dev/prod) this is executing in
    if (true == true) {
      taskLogDriver = AwsLogDriver.Builder.create()
          .streamPrefix("TFC_AGENT_")
          .build();
    } else {
      taskLogDriver = SplunkLogDriver.Builder.create()
          .format(SplunkLogFormat.RAW)
          .index("terraform-agent")
          .source("terraform-agent-stdout")
          .sourceType("stdout")
          .url("https://http-inputs.clevertap.splunkcloud.com")
          .verifyConnection(false)
          .secretToken(Secret.fromSecretsManager(agentServiceStackProps.getSplunkHecToken()))
          .build();
    }

    terraformAgentEcsTaskDefinition.addContainer("TerraformAgent",
        ContainerDefinitionOptions.builder()
            .essential(true)
            .environment(terraformAgentContainerEnvironment)
            .secrets(terraformAgentContainerSecrets)
            .image(ContainerImage.fromRegistry("hashicorp/tfc-agent"))
            .logging(taskLogDriver)
            /*.logging()

             */
            .memoryReservationMiB(512)
            .containerName(Aws.STACK_NAME + "TfAgent")
            .privileged(false)
            .readonlyRootFilesystem(false)
            .build());

    FargateService TerraformAgentEcsService = FargateService.Builder.create(this,
            "TerraformAgentEcsService")
        .cluster(agentServiceStackProps.getCluster())
        .desiredCount(0)
        .enableExecuteCommand(true)
        .propagateTags(PropagatedTagSource.SERVICE)
        .minHealthyPercent(0)
        .maxHealthyPercent(100)
        .vpcSubnets(SubnetSelection.builder()
            .subnetType(SubnetType.PRIVATE_WITH_EGRESS)
            .build())
        .assignPublicIp(false)
        .taskDefinition(terraformAgentEcsTaskDefinition)
        .build();

    Tags.of(TerraformAgentEcsService).add("ct-aws:cloudformation:stack-name", Aws.STACK_NAME);

  }


}
