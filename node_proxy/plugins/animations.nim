import macros, tables
import .. / plugin


proc withNodeProxyPlugin*(data: NodeProxyPluginData) =
    data.checkArgs()

    let propName = data.prop.getPropNameIdent()
    let key = data.props["withKey"]
    var target = data.props.getOrDefault("forNode")
    if target.isNil:
        target = ident("node")
    if target.kind == nnkIdent:
        target = nnkDotExpr.newTree(NP, target)
    elif target.kind == nnkStrLit:
        target = quote:
            `NP`.node.findNode(`target`)
    
    let propNameLit = newLit($propName)
    let oninit = quote:
        `NP`.`propName` = `target`.animationNamed(`key`)
        assert(`NP`.`propName`.isNil != true, "Animation `" & `key` & "` for prop `" & `propNameLit` & "` isNil")
    
    if not oninit.isNil:
        data.init.add(oninit)

static:
    registerPlugin("withKey", withNodeProxyPlugin)