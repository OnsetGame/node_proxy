import macros, tables

let NP* {.compiletime.} = ident("np")

type NodeProxyPluginData* = ref object
    body*: NimNode
    T*: NimNode
    props*: OrderedTable[string, NimNode]
    prop*: NimNode
    propBody*: NimNode
    init*: NimNode


proc checkArgs*(data: NodeProxyPluginData) =
    data.T.expectKind(nnkIdent)
    data.body.expectKind(nnkStmtList)
    data.prop.expectKind(nnkIdentDefs)
    data.propBody.expectKind(nnkStmtList)
    data.init.expectKind(nnkStmtList)


type NodeProxyPlugin* = proc(data: NodeProxyPluginData) 


proc getTypeSection*(n: NimNode): NimNode =
    n.expectKind(nnkStmtList)
    for x in n:
        if x.kind == nnkTypeSection:
            return x

proc getTypeDef*(n: NimNode, name: string): NimNode =
    n.expectKind(nnkTypeSection)
    for x in n:
        var nn = x[0]
        if x[0].kind == nnkPostfix:
            nn = nn[1]
        if nn.eqIdent(name):
            return x

proc getRecList*(n: NimNode): NimNode =
    n.expectKind(nnkTypeDef)
    result = n[2][0][2]


proc getRecListFor*(n: NimNode, name: string): NimNode =
    n.getTypeDef(name).getRecList()


proc getPropNameIdent*(prop: NimNode): NimNode =
    if prop.isNil:
        return
    prop.expectKind(nnkIdentDefs)
    if prop[0].kind == nnkIdent:
        return prop[0]
    elif prop[0].kind == nnkPostfix:
        return prop[0][1]
    else:
        error "Unexpected AST\n" & treeRepr(prop)

proc getPropTypeIdent*(prop: NimNode): NimNode =
    return prop[1]

proc isPublic*(prop: NimNode): bool =
    prop.expectKind(nnkIdentDefs)
    result = prop[0].kind == nnkPostfix

var pluginsRegistry {.compiletime.} = initOrderedTable[string, seq[NodeProxyPlugin]]()
proc registerPlugin*(prop: string, plugin: NodeProxyPlugin) {.compiletime.} =
    var reg = pluginsRegistry.getOrDefault(prop)
    reg.add(plugin)
    pluginsRegistry[prop] = reg


proc pluginsForProp*(name: string): seq[NodeProxyPlugin] {.compiletime.} =
    pluginsRegistry.getOrDefault(name)


proc pluginsForProp*(name: NimNode): seq[NodeProxyPlugin] {.compiletime.} =
    if name.kind == nnkStrLit:
        result = pluginsForProp(name.strVal)
    elif name.kind == nnkIdent:
        result = pluginsForProp($name.ident)
    else:
        error "Unexpected AST\n" & treeRepr(name)


proc isDiscard*(n: NimNode): bool =
    result = n.isNil or n.len == 0 or (n.kind == nnkStmtList and n[0].kind == nnkDiscardStmt)


proc injectDots*(n: NimNode, prop: NimNode) =
    let propName = prop.getPropNameIdent()
    var target = n
    while target[0].kind == nnkDotExpr:
        target = target[0]
    
    if propName.isNil:
        target[0] = nnkDotExpr.newTree(
            NP,
            target[0]
        )
    else:
        target[0] = nnkDotExpr.newTree(
            nnkDotExpr.newTree(
                NP,
                propName
            ),
            target[0]
        )
