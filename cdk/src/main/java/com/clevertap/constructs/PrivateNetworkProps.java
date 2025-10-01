package com.clevertap.constructs;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Builder
@Getter
public class PrivateNetworkProps {
    private final String networkStack;
    private final List<String> availabilityZones;
    private final List<String> subnetCidrBlocks;
    private final StackProvisioningMode stackProvisioningMode;
    private final PrivateNetworkSubnetType subnetType;
    private final List<String> natGatewayIds;
}