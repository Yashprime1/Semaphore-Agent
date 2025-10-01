package com.clevertap;

import com.clevertap.stacks.*;
import software.amazon.awscdk.App;

public class CdkApp {
    public static void main(final String[] args) {
        App app = App.Builder.create()
                .analyticsReporting(false)
                .treeMetadata(false)
                .build();

        new TerraformAgentServiceStack(app, "System-Terraform-Agent", TerraformAgentServiceStackProps.builder()
                .networkStack("System-Network")
                .systemStack("System")
                .taskCpu("256")
                .taskMemoryMib("512")
                .desiredCount(1)
                .enableDeploymentCircuitBreaker(true)
                .build());
        
        app.synth();
    }
}
