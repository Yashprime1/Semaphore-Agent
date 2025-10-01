package com.clevertap.stacks;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class TerraformAgentServiceStackProps {
    private final String networkStack;
    private final String systemStack;
    private final String taskCpu;
    private final String taskMemoryMib;
    private final Number desiredCount;
    private final Boolean enableDeploymentCircuitBreaker;
}


