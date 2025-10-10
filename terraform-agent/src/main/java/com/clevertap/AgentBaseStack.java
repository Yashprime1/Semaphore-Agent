package com.clevertap;

import software.amazon.awscdk.SecretValue;
import software.amazon.awscdk.Stack;
import software.amazon.awscdk.StackProps;
import software.amazon.awscdk.services.ecs.Cluster;
import software.amazon.awscdk.services.secretsmanager.Secret;
import software.constructs.Construct;
import lombok.Getter;

@Getter
public class AgentBaseStack extends Stack {

  private final Secret splunkHecToken;
  private final Secret tfcAgentToken;
  private final Cluster cluster;

  public AgentBaseStack(final Construct scope, final String id, final StackProps props,
      AgentBaseStackProps agentBaseStack) {
    super(scope, id, null);

    this.splunkHecToken = Secret.Builder.create(this, "SplunkHecToken")
        .description("SplunkHecToken for Service")
        .secretStringValue(SecretValue.unsafePlainText("PLACEHOLDER_VALUE_UPDATE_MANUALLY"))
        .build();

    this.tfcAgentToken = Secret.Builder.create(this, "TcfAgentToken")
        .description("TCF_AGENT_TOKEN for Service")
        .secretStringValue(SecretValue.unsafePlainText("PLACEHOLDER_VALUE_UPDATE_MANUALLY"))
        .build();

    this.cluster = Cluster.Builder.create(this, "AgentServiceEc2Cluster")
        .vpc(agentBaseStack.getVpc())
        .build();
  }
}
