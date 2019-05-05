#pragma once

#include <AzCore/Component/Component.h>

#include <LD44Playground/LD44PlaygroundBus.h>

namespace LD44Playground
{
    class LD44PlaygroundSystemComponent
        : public AZ::Component
        , protected LD44PlaygroundRequestBus::Handler
    {
    public:
        AZ_COMPONENT(LD44PlaygroundSystemComponent, "{F739F320-DF04-4588-8CF2-AAEFE29F5A09}");

        static void Reflect(AZ::ReflectContext* context);

        static void GetProvidedServices(AZ::ComponentDescriptor::DependencyArrayType& provided);
        static void GetIncompatibleServices(AZ::ComponentDescriptor::DependencyArrayType& incompatible);
        static void GetRequiredServices(AZ::ComponentDescriptor::DependencyArrayType& required);
        static void GetDependentServices(AZ::ComponentDescriptor::DependencyArrayType& dependent);

    protected:
        ////////////////////////////////////////////////////////////////////////
        // LD44PlaygroundRequestBus interface implementation

        ////////////////////////////////////////////////////////////////////////

        ////////////////////////////////////////////////////////////////////////
        // AZ::Component interface implementation
        void Init() override;
        void Activate() override;
        void Deactivate() override;
        ////////////////////////////////////////////////////////////////////////
    };
}
