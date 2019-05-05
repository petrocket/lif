
#include <AzCore/Memory/SystemAllocator.h>
#include <AzCore/Module/Module.h>

#include <LD44PlaygroundSystemComponent.h>

namespace LD44Playground
{
    class LD44PlaygroundModule
        : public AZ::Module
    {
    public:
        AZ_RTTI(LD44PlaygroundModule, "{FFE6B310-5957-4661-A8F7-D4017B248508}", AZ::Module);
        AZ_CLASS_ALLOCATOR(LD44PlaygroundModule, AZ::SystemAllocator, 0);

        LD44PlaygroundModule()
            : AZ::Module()
        {
            // Push results of [MyComponent]::CreateDescriptor() into m_descriptors here.
            m_descriptors.insert(m_descriptors.end(), {
                LD44PlaygroundSystemComponent::CreateDescriptor(),
            });
        }

        /**
         * Add required SystemComponents to the SystemEntity.
         */
        AZ::ComponentTypeList GetRequiredSystemComponents() const override
        {
            return AZ::ComponentTypeList{
                azrtti_typeid<LD44PlaygroundSystemComponent>(),
            };
        }
    };
}

// DO NOT MODIFY THIS LINE UNLESS YOU RENAME THE GEM
// The first parameter should be GemName_GemIdLower
// The second should be the fully qualified name of the class above
AZ_DECLARE_MODULE_CLASS(LD44Playground_bae6b0643dd14c2790a9f0f57fdf8792, LD44Playground::LD44PlaygroundModule)
