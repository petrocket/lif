#pragma once

#include <AzCore/EBus/EBus.h>

namespace LD44Playground
{
    class LD44PlaygroundRequests
        : public AZ::EBusTraits
    {
    public:
        //////////////////////////////////////////////////////////////////////////
        // EBusTraits overrides
        static const AZ::EBusHandlerPolicy HandlerPolicy = AZ::EBusHandlerPolicy::Single;
        static const AZ::EBusAddressPolicy AddressPolicy = AZ::EBusAddressPolicy::Single;
        //////////////////////////////////////////////////////////////////////////

        // Put your public methods here
    };
    using LD44PlaygroundRequestBus = AZ::EBus<LD44PlaygroundRequests>;
} // namespace LD44Playground
