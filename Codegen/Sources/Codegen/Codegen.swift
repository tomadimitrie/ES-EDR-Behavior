import EndpointSecurity

@freestanding(declaration, names: named(allEvents))
public macro generateESEventNames() = #externalMacro(module: "CodegenMacros", type: "GenerateESEventNamesMacro")
