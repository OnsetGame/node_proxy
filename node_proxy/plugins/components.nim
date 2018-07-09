import macros, tables
import .. / plugin


proc onNodeProxyPlugin*(data: NodeProxyPluginData) =
    data.checkArgs()

    let propName = data.prop.getPropNameIdent()
    let propType = data.prop.getPropTypeIdent()
    var node = data.props["onNode"]
    if node.kind == nnkIdent:
        node = nnkDotExpr.newTree(NP, node)
    elif node.kind == nnkStrLit:
        node = quote:
            `NP`.node.findNode(`node`)
    
    let propNameLit = newLit($propName)
    let propTypeLit = newLit($propType)
    let oninit = quote:
        `NP`.`propName` = `node`.getComponent(`propType`)
        assert(`NP`.`propName`.isNil != true, "Component `" & `propTypeLit` & "` for prop `" & `propNameLit` & "` is nil")
    
    if not oninit.isNil:
        data.init.add(oninit)

static:
    registerPlugin("onNode", onNodeProxyPlugin)


proc onNodeAddNodeProxyPlugin*(data: NodeProxyPluginData) =
    data.checkArgs()

    let propName = data.prop.getPropNameIdent()
    let propType = data.prop.getPropTypeIdent()
    var node = data.props["onNodeAdd"]
    if node.kind == nnkIdent:
        node = nnkDotExpr.newTree(NP, node)
    elif node.kind == nnkStrLit:
        node = quote:
            `NP`.node.findNode(`node`)

    let propNameLit = newLit($propName)
    let propTypeLit = newLit($propType)
    let oninit = quote:
        when defined(debugNodeProxy):
            if not `node`.getComponent(`propType`).isNil:
                echo "Component `" & `propTypeLit` & "` for prop `" & `propNameLit` & "` has been already added"
        `NP`.`propName` = `node`.addComponent(`propType`)
    
    if not oninit.isNil:
        data.init.add(oninit)

static:
    registerPlugin("onNodeAdd", onNodeAddNodeProxyPlugin)