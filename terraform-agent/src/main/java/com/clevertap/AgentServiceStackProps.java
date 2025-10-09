package com.clevertap;

import software.amazon.awscdk.services.ec2.Vpc;
import software.amazon.awscdk.services.ecs.Cluster;
import software.amazon.awscdk.services.secretsmanager.Secret;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AgentServiceStackProps {

  private final Secret splunkHecToken;
  private final Secret tcfAgentToken;
  private final Vpc vpc;
  private final Cluster cluster;
}
