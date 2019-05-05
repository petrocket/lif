
#include <AzCore/Serialization/SerializeContext.h>
#include <AzCore/Serialization/EditContext.h>
#include <AzCore/Serialization/EditContextConstants.inl>

#include <LD44PlaygroundSystemComponent.h>

namespace LD44Playground
{
    void LD44PlaygroundSystemComponent::Reflect(AZ::ReflectContext* context)
    {
        if (AZ::SerializeContext* serialize = azrtti_cast<AZ::SerializeContext*>(context))
        {
            serialize->Class<LD44PlaygroundSystemComponent, AZ::Component>()
                ->Version(0)
                ;

            if (AZ::EditContext* ec = serialize->GetEditContext())
            {
                ec->Class<LD44PlaygroundSystemComponent>("LD44Playground", "[Description of functionality provided by this System Component]")
                    ->ClassElement(AZ::Edit::ClassElements::EditorData, "")
                        ->Attribute(AZ::Edit::Attributes::AppearsInAddComponentMenu, AZ_CRC("System"))
                        ->Attribute(AZ::Edit::Attributes::AutoExpand, true)
                    ;
            }
        }
    }

    void LD44PlaygroundSystemComponent::GetProvidedServices(AZ::ComponentDescriptor::DependencyArrayType& provided)
    {
        provided.push_back(AZ_CRC("LD44PlaygroundService"));
    }

    void LD44PlaygroundSystemComponent::GetIncompatibleServices(AZ::ComponentDescriptor::DependencyArrayType& incompatible)
    {
        incompatible.push_back(AZ_CRC("LD44PlaygroundService"));
    }

    void LD44PlaygroundSystemComponent::GetRequiredServices(AZ::ComponentDescriptor::DependencyArrayType& required)
    {
        AZ_UNUSED(required);
    }

    void LD44PlaygroundSystemComponent::GetDependentServices(AZ::ComponentDescriptor::DependencyArrayType& dependent)
    {
        AZ_UNUSED(dependent);
    }

    void LD44PlaygroundSystemComponent::Init()
    {
    }

    void LD44PlaygroundSystemComponent::Activate()
    {
        LD44PlaygroundRequestBus::Handler::BusConnect();
    }

    void LD44PlaygroundSystemComponent::Deactivate()
    {
        LD44PlaygroundRequestBus::Handler::BusDisconnect();
    }
}
