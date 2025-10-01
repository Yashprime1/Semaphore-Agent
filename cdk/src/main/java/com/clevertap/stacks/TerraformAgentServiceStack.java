package com.clevertap.stacks;

import java.util.List;

import com.clevertap.constructs.PrivateNetwork;
import com.clevertap.constructs.PrivateNetworkProps;
import com.clevertap.constructs.PrivateNetworkSubnetType;

import software.amazon.awscdk.Aws;
import software.amazon.awscdk.CfnParameter;
import software.amazon.awscdk.Fn;
import software.amazon.awscdk.Stack;
import software.amazon.awscdk.StackProps;
import software.amazon.awscdk.Tags;
import software.amazon.awscdk.services.ec2.IVpc;
import software.amazon.awscdk.services.ec2.Vpc;
import software.amazon.awscdk.services.ec2.VpcAttributes;
import software.amazon.awscdk.services.ecs.*;
import software.amazon.awscdk.services.iam.Effect;
import software.amazon.awscdk.services.iam.ManagedPolicy;
import software.amazon.awscdk.services.iam.PolicyStatement;
import software.amazon.awscdk.services.iam.Role;
import software.amazon.awscdk.services.iam.ServicePrincipal;
import software.amazon.awscdk.services.secretsmanager.ISecret;
import software.amazon.awscdk.services.secretsmanager.Secret;
import software.amazon.awscdk.services.secretsmanager.SecretAttributes;
import software.constructs.Construct;
import com.clevertap.constructs.StackProvisioningMode;

import java.util.HashMap;
import java.util.Map;

public class TerraformAgentServiceStack extends Stack {
    public TerraformAgentServiceStack(final Construct parent, final String id, TerraformAgentServiceStackProps TerraformAgentServiceStackProps) {
        this(parent, id, null, TerraformAgentServiceStackProps);
    }

    public TerraformAgentServiceStack(final Construct parent, final String id, final StackProps props, TerraformAgentServiceStackProps TerraformAgentServiceStackProps) {
        super(parent, id, props);

        List<String> availabilityZones = List.of("a","b");
        List<String> subnetCidrBlocks = List.of("35.0/28", "35.16/28");
        CfnParameter TerraformAgentContainerTag = CfnParameter.Builder.create(this, "ContainerTag")
            .type("String")
            .build();

        PrivateNetwork TerraformAgentPrivateNetwork = new PrivateNetwork(this, "TerraformAgentPrivateNetwork", PrivateNetworkProps.builder()
            .availabilityZones(availabilityZones)
            .networkStack(TerraformAgentServiceStackProps.getNetworkStack())
            .subnetCidrBlocks(subnetCidrBlocks)
            .stackProvisioningMode(StackProvisioningMode.PROD)
            .subnetType(PrivateNetworkSubnetType.WITH_EGRESS)
            .build());
        
        IVpc vpc = Vpc.fromVpcAttributes(this, "Vpc", VpcAttributes.builder()
            .vpcId(Fn.importValue(TerraformAgentServiceStackProps.getNetworkStack() + "-VpcId"))
            .availabilityZones(availabilityZones)
            .build());

        Cluster TerraformAgentEcsCluster =  new Cluster(this, "TerraformAgentEcsCluster", ClusterProps.builder()
            .vpc(vpc)
            .build());

        Map<String, String> terraformAgentContainerEnvironment = new HashMap<>();
        terraformAgentContainerEnvironment.put("TFC_AGENT_NAME", "terraform-agent");
        terraformAgentContainerEnvironment.put("TFC_AGENT_SINGLE", "true");
        
        Map<String, software.amazon.awscdk.services.ecs.Secret> terraformAgentContainerSecrets = new HashMap<>();
        terraformAgentContainerSecrets.put("TFC_AGENT_TOKEN",
                software.amazon.awscdk.services.ecs.Secret.fromSecretsManager(Secret.fromSecretAttributes(this, "TerraformAgentApiKeySecretsManagerSecret", SecretAttributes.builder()
                        .secretCompleteArn(Fn.importValue(TerraformAgentServiceStackProps.getSystemStack() + "-SharedResources-TerraformAgentApiKeySecretsManagerSecretArn"))
                        .build())));
        
        Role TerraformAgentEcsTaskExecutionIamRole = Role.Builder.create(this, "TerraformAgentEcsTaskExecutionIamRole")
            .assumedBy(new ServicePrincipal("ecs-tasks.amazonaws.com"))
            .path("/")
            .build();

        ManagedPolicy.Builder.create(this, "TerraformAgentEcsTaskExecutionIamPolicy")
            .roles(List.of(TerraformAgentEcsTaskExecutionIamRole))
            .statements(List.of(
                PolicyStatement.Builder.create()
                    .effect(Effect.ALLOW)
                    .actions(List.of(
                        "secretsmanager:GetSecretValue"
                    ))
                    .resources(List.of(
                        Fn.importValue(TerraformAgentServiceStackProps.getSystemStack() + "-SharedResources-TerraformAgentApiKeySecretsManagerSecretArn")
                    ))
                    .sid("AllowSecretsRetreiveValue")
                    .build()
            ))
            .build();

        TaskDefinition TerraformAgentEcsTaskDefinition = new TaskDefinition(this, "TerraformAgentEcsTaskDefinition", TaskDefinitionProps.builder()
            .compatibility(Compatibility.FARGATE)
            .cpu(TerraformAgentServiceStackProps.getTaskCpu())
            .memoryMiB(TerraformAgentServiceStackProps.getTaskMemoryMib())
            .networkMode(NetworkMode.AWS_VPC)
            .family(Aws.STACK_NAME)
            .executionRole(TerraformAgentEcsTaskExecutionIamRole)
            .build());


        ISecret artifactoryDockerUserCredentials = Secret.fromSecretAttributes(this, "ArtifactoryDockerUserCredentialsSecretsManagerSecret", SecretAttributes.builder()
                .secretCompleteArn(Fn.importValue(TerraformAgentServiceStackProps.getSystemStack() + "-SharedResources-ArtifactoryDockerUserCredentialsSecretsManagerSecretArn"))
                .build());

        ISecret splunkTokenSecret = Secret.fromSecretAttributes(this, "SplunkTokenSecretsManagerSecret", SecretAttributes.builder()
                .secretCompleteArn(Fn.importValue(TerraformAgentServiceStackProps.getSystemStack() + "-SharedResources-SplunkTokenSecretsManagerSecretArn"))
                .build());


        TerraformAgentEcsTaskDefinition.addContainer("TerraformAgent", ContainerDefinitionOptions.builder()
            .essential(true)
            .environment(terraformAgentContainerEnvironment)
            .secrets(terraformAgentContainerSecrets)
            .image(ContainerImage.fromRegistry(TerraformAgentServiceStackProps.getNetworkStack() + ".registry.clevertap-internal.io/docker/hashicorp/tfc-agent:" + TerraformAgentContainerTag.getValueAsString(), RepositoryImageProps.builder()
                    .credentials(artifactoryDockerUserCredentials)
                    .build()))
            .logging(SplunkLogDriver.Builder.create()
                        .format(SplunkLogFormat.RAW)
                        .index("terraform-agent")
                        .source("terraform-agent-stdout")
                        .sourceType("stdout")
                        .url("https://http-inputs.clevertap.splunkcloud.com")
                        .verifyConnection(false)
                        .secretToken(software.amazon.awscdk.services.ecs.Secret.fromSecretsManager(splunkTokenSecret, "splunk-token"))
                        .build())
                .memoryReservationMiB(256)
                .containerName(Aws.STACK_NAME)
                .privileged(false)
                .readonlyRootFilesystem(false)
                .ulimits(List.of(
                        Ulimit.builder()
                                .name(UlimitName.NOFILE)
                                .hardLimit(900000)
                                .softLimit(900000)
                                .build()
                ))
           .build());



        
        FargateService TerraformAgentEcsService = FargateService.Builder.create(this, "TerraformAgentEcsService")
                .cluster(TerraformAgentEcsCluster)
                .desiredCount(TerraformAgentServiceStackProps.getDesiredCount())
                .enableExecuteCommand(true)
                .propagateTags(PropagatedTagSource.SERVICE)
                .minHealthyPercent(100)
                .maxHealthyPercent(200)
                .vpcSubnets(TerraformAgentPrivateNetwork.getSubnetSelection())
                .assignPublicIp(false)
                .taskDefinition(TerraformAgentEcsTaskDefinition)
                .circuitBreaker(TerraformAgentServiceStackProps.getEnableDeploymentCircuitBreaker() ? DeploymentCircuitBreaker.builder()
                        .enable(true)
                        .rollback(true)
                        .build() : null)
                .build();

        Tags.of(TerraformAgentEcsService).add("ct-aws:cloudformation:stack-name", Aws.STACK_NAME);


    }
}
