package com.clevertap;

import lombok.Builder;
import lombok.Getter;
import software.amazon.awscdk.services.ec2.Vpc;

@Getter
@Builder

public class AgentBaseStackProps {

  private final Vpc vpc;
}
