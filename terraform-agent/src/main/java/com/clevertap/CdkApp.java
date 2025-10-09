package com.clevertap;

import software.amazon.awscdk.App;

public class CdkApp {

  public static void main(final String[] args) {
    App app = new App();

    NetworkStack networkStack = new NetworkStack(app, "TfAgent-Network",
        null);

    AgentBaseStack agentBaseStack = new AgentBaseStack(app, "TfAgent-AgentBase", null,
        AgentBaseStackProps.builder()
        .vpc(networkStack.getVpc())
        .build());

    AgentServiceStack agentServiceStack = new AgentServiceStack(app, "Tf-Agent-AgentService",
        null, AgentServiceStackProps.builder()
        .vpc(networkStack.getVpc())
        .cluster(agentBaseStack.getCluster())
        .splunkHecToken(agentBaseStack.getSplunkHecToken())
        .tcfAgentToken(agentBaseStack.getTfcAgentToken())
        .build()
    );

    app.synth();
  }
}

