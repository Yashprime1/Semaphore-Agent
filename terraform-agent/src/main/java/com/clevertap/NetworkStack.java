package com.clevertap;

import software.amazon.awscdk.services.ec2.CfnEIP;
import software.amazon.awscdk.services.ec2.CfnEIPAssociation;
import software.amazon.awscdk.services.ec2.Instance;
import software.amazon.awscdk.services.ec2.InstanceType;
import software.amazon.awscdk.services.ec2.IpAddresses;
import software.amazon.awscdk.services.ec2.NatInstanceProps;
import software.amazon.awscdk.services.ec2.NatInstanceProviderV2;
import software.amazon.awscdk.services.ec2.NatTrafficDirection;
import software.amazon.awscdk.services.ec2.Peer;
import software.amazon.awscdk.services.ec2.Port;
import software.amazon.awscdk.services.ec2.SecurityGroup;
import software.amazon.awscdk.services.ec2.Vpc;
import software.constructs.Construct;
import software.amazon.awscdk.Stack;
import software.amazon.awscdk.StackProps;
// import software.amazon.awscdk.Duration;
// import software.amazon.awscdk.services.sqs.Queue;
import lombok.Getter;
@Getter
public class NetworkStack extends Stack {

  private final Vpc vpc;

  public NetworkStack(final Construct scope, final String id) {
    this(scope, id, null);
  }

  public NetworkStack(final Construct scope, final String id, final StackProps props) {
    super(scope, id, props);

    NatInstanceProviderV2 natGatewayProvider = NatInstanceProviderV2.instanceV2(
        NatInstanceProps.builder()
            .instanceType(new InstanceType("t4g.nano"))
            .defaultAllowedTraffic(NatTrafficDirection.NONE)
            .build());

    this.vpc = Vpc.Builder.create(this, "Vpc")
        .ipAddresses(IpAddresses.cidr("10.0.0.0/20"))
        .maxAzs(2)
        .natGatewayProvider(natGatewayProvider)
        .build();

    SecurityGroup natInstanceSecurityGroup = SecurityGroup.Builder.create(this,
            "NatInstanceSecurityGroup")
        .vpc(vpc)
        .allowAllOutbound(true)
        .build();

    natInstanceSecurityGroup.addIngressRule(Peer.ipv4(vpc.getVpcCidrBlock()), Port.allTcp());

    for (int i = 0; i < natGatewayProvider.getGatewayInstances().size(); i++) {
      Instance gatewayInstance = natGatewayProvider.getGatewayInstances().get(i);
      gatewayInstance.addSecurityGroup(natInstanceSecurityGroup);
      
      // Create Elastic IP for this NAT instance
      CfnEIP elasticIP = CfnEIP.Builder.create(this, "NatInstanceEIP" + i)
          .domain("vpc")
          .build();
      
      // Associate Elastic IP with NAT instance
      CfnEIPAssociation.Builder.create(this, "NatInstanceEIPAssociation" + i)
          .instanceId(gatewayInstance.getInstanceId())
          .allocationId(elasticIP.getAttrAllocationId())
          .build();
    }
  }
}
