package com.clevertap.constructs;

import java.util.*;

import lombok.Getter;
import software.amazon.awscdk.Aws;
import software.amazon.awscdk.CfnTag;
import software.amazon.awscdk.Fn;
import software.constructs.Construct;
import software.amazon.awscdk.services.ec2.*;

@Getter
public class PrivateNetwork extends Construct {
    private final SubnetSelection subnetSelection;

    public PrivateNetwork(final Construct scope, final String id, final PrivateNetworkProps props) {
        super(scope, id);

        List<ISubnet> subnets = new ArrayList<>();
        List<String> availabilityZones = props.getAvailabilityZones();
        List<String> subnetCidrBlocks = props.getSubnetCidrBlocks();
        List<String> natGatewayIds = props.getNatGatewayIds();

        IVpc vpc = Vpc.fromVpcAttributes(this, "Vpc", VpcAttributes.builder()
                .vpcId(Fn.importValue(props.getNetworkStack() + "-VpcId"))
                .availabilityZones(availabilityZones)
                .build());

        for (int i = 0; i < availabilityZones.size(); i++) {
            Subnet privateEc2Subnet = Subnet.Builder.create(this, "Az" + availabilityZones.get(i).toUpperCase() + "Ec2Subnet")
                    .availabilityZone(Aws.REGION + availabilityZones.get(i))
                    .vpcId(Fn.importValue(props.getNetworkStack() + "-VpcId"))
                    .mapPublicIpOnLaunch(false)
                    .cidrBlock(Fn.join(".",
                            List.of(Fn.importValue(props.getNetworkStack() + "-VpcNetworkPrefix"),
                                    subnetCidrBlocks.get(i))))
                    .build();

            subnets.add(privateEc2Subnet);

            if (props.getSubnetType().equals(PrivateNetworkSubnetType.WITH_EGRESS)) {
                String routerId =  Fn.importValue(props.getNetworkStack() + "-Nat1" + availabilityZones.get(i).toLowerCase() + "Ec2InstanceId");
                RouterType routerType = RouterType.INSTANCE;

                if (props.getStackProvisioningMode().equals(StackProvisioningMode.PROD)) {
                    if (natGatewayIds == null) {
                        CfnEIP natGateWayEip = CfnEIP.Builder.create(this, "Az" + availabilityZones.get(i).toUpperCase() + "NatGatewayEc2Eip")
                                .domain("vpc")
                                .build();

                        CfnNatGateway natGateway = CfnNatGateway.Builder.create(this, "Az" + availabilityZones.get(i).toUpperCase() + "Ec2NatGateway")
                                .allocationId(natGateWayEip.getAttrAllocationId())
                                .subnetId(Fn.importValue(props.getNetworkStack() + "-Nat-Network-PublicAz" + availabilityZones.get(i).toUpperCase() + "Ec2SubnetId"))
                                .tags(List.of(
                                        CfnTag.builder()
                                                .key("ct-aws:cloudformation:stack-name")
                                                .value(Aws.STACK_NAME)
                                                .build()))
                                .build();

                        routerId = natGateway.getAttrNatGatewayId();
                    } else {
                        routerId = natGatewayIds.get(i);
                    }
                    routerType = RouterType.NAT_GATEWAY;
                }

                privateEc2Subnet.addRoute("Az" + availabilityZones.get(i).toUpperCase() + "NatEc2Route",
                        AddRouteOptions.builder()
                                .routerId(routerId)
                                .routerType(routerType)
                                .enablesInternetConnectivity(true)
                                .build()
                );
            }

            ISubnet privateEc2ISubnet = Subnet.fromSubnetAttributes(this,
                    "Az" + availabilityZones.get(i).toUpperCase() + "IEc2Subnet",
                    SubnetAttributes.builder()
                            .subnetId(privateEc2Subnet.getSubnetId())
                            .routeTableId(privateEc2Subnet.getRouteTable().getRouteTableId())
                            .build()
            );

            GatewayVpcEndpoint.Builder.create(this, "Az" + availabilityZones.get(i).toUpperCase() + "Ec2SubnetS3GatewayEc2VpcEndpoint")
                    .vpc(vpc)
                    .service(GatewayVpcEndpointAwsService.S3)
                    .subnets(List.of(SubnetSelection.builder()
                            .subnets(List.of(privateEc2ISubnet))
                            .build()))
                    .build();
        }

        this.subnetSelection = SubnetSelection.builder()
                .subnets(subnets)
                .build();
    }
}