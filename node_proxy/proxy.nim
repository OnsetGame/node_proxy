import tables, macros
import rod / node
import plugin
import plugins / [animations, components, nodes, ctors, observarbles]

import plugins / observarble_component
export observarble_component

type NodeProxy* = ref object of RootObj
    node*: Node


proc init*(np: NodeProxy, node: Node) =
    np.node = node


proc new*(T: typedesc[NodeProxy], node: Node): T =
    var res = T.new()
    res.init(node)
    result = res


template getType(T, TT): untyped =
    type T* = ref object of TT

proc getPropDef(name, typ: NimNode, public: bool): NimNode =
    result = nnkIdentDefs.newTree()
    if public:
        result.add(nnkPostfix.newTree(ident("*"), name))
    else:
        result.add(name)
    result.add(typ)
    result.add(newEmptyNode())

proc toNodeProxy(x: NimNode, y: NimNode = nil): NimNode =
    let res = nnkStmtList.newTree()

    var T = x
    var TT = ident("NodeProxy")

    if T.kind == nnkInfix:
        if not T[0].eqIdent("of"):
            error "Unexpected infix node\n" & treeRepr(T)
        TT = T[2]
        T = T[1]

    T.expectKind(nnkIdent)
    
    let typeDef = getAst(getType(T, TT))
    res.add(typeDef)
    typedef[0][2][0][2] = nnkRecList.newTree()
    let typeProps = typedef[0][2][0][2]

    if y.isDiscard():
        return res
    
    var initProc = quote:
        proc init*(`NP`: `T`, node: Node) =
            `NP`.`TT`.init(node)

    let init = initProc[6]
    
    let pluginData = NodeProxyPluginData(body: res, T: T, init: init)
    
    proc applyPlugins() =
        if pluginData.propBody.isNil:
            pluginData.propBody = nnkStmtList.newTree()

        if not pluginData.propBody.isDiscard():
            for propItem in pluginData.propBody:
                injectDots(propItem, pluginData.prop)

        for k in pluginData.props.keys():
            for plugin in pluginsForProp(k):
                plugin(pluginData)

        if not pluginData.propBody.isDiscard():
            for propItem in pluginData.propBody:
                init.add(propItem)

    proc getPluginDataProps(n: NimNode): OrderedTable[string, NimNode] =
        n.expectKind(nnkTableConstr)
        result = initOrderedTable[string, NimNode]()
        for pp in n:
            pp.expectKind(nnkExprColonExpr)
            pp[0].expectKind(nnkIdent)
            result[$pp[0].ident] = pp[1]

    proc flattenCommands(n: NimNode, kinds: set[NimNodeKind], res: var seq[NimNode]) =
        if n.kind in kinds:
            for c in n: flattenCommands(c, kinds, res)
        else:
            res.add(n)

    for p in y:
        var args: seq[NimNode]
        flattenCommands(p, {nnkCommand, nnkInfix}, args)
        var i = 0

        var public = false
        if args[i].kind == nnkIdent and $args[i] == "*":
            public = true
            inc i

        let name = args[i]
        inc i

        let typ = args[i]
        inc i

        pluginData.prop = getPropDef(name, typ, public)

        if i < args.len:
            let arg = args[i]
            if arg.kind == nnkStmtList:
                for c in arg:
                    flattenCommands(c, {nnkCall}, args)
                inc i

            while i < args.len:
                pluginData.props = getPluginDataProps(args[i])
                inc i
                if i < args.len and args[i].kind == nnkStmtList:
                    pluginData.propBody = args[i]
                    inc i
                else:
                    pluginData.propBody = nil
                applyPlugins()

        typeProps.add(pluginData.prop)

    res.add(initProc)
    
    let TI = ident("T")
    let I = ident("init")
    let R = ident("result")
    let newProc = quote do:
        proc new*(`TI`: typedesc[`T`], node: Node): `TI` =
            `R` = `TI`.new()
            `R`.`I`(node)
    res.add(newProc)

    result = res


macro nodeProxy*(x: untyped, y: untyped = nil): untyped =
    result = toNodeProxy(x, y)

    when defined(debugNodeProxy):
        echo "\ngen finished \n ", repr(result)

#[
    Extensions
]#

when isMainModule:
    import rod/node
    import rod/viewport
    import rod/rod_types
    import rod/component
    import rod/component / [ sprite, solid, camera, text_component ]
    import nimx / [ animation, types, matrixes ]
    import observarble

    proc nodeForTest(): Node =
        result = newNode("test")
        var child1 = result.newChild("child1")

        var a = newAnimation()
        a.loopDuration = 1.0
        a.numberOfLoops = 10
        child1.registerAnimation("animation", a)

        var child2 = result.newChild("child2")
        discard child2.newChild("sprite")

        var child3 = child2.newChild("somenode")
        discard child3.component(Text)

        discard result.newChild("someothernode")

        a = newAnimation()
        a.loopDuration = 1.0
        a.numberOfLoops = 10
        result.registerAnimation("in", a)

    proc getSomeEnabled(): bool = result = true
    
    observarble MyObservarble:
        name* string

    nodeProxy TestProxy:
        obj MyObservarble

        someNode Node {withName: "somenode"}:
            parent.enabled = false

        nilNode Node {addTo: someNode}:
            alpha = 0.1
            enabled = getSomeEnabled()

        someNode2 Node {addTo: nilNode, withName: "somenode"}:
            parent.enabled = false

        text* Text {onNode: "somenode"}:
            text = "some text"

        child Node {withName: "child1"}

        text2* Text: 
            {onNodeAdd: nilNode}:
                bounds = newRect(20.0, 20.0, 100.0, 100.0)
            {observe: obj}:
                text = np.obj.name

        source int {withValue: 100500}
        source2 int {withValue: proc(np: TestProxy): int = result = 1060}

        anim Animation {withKey: "animation", forNode: child}:
            numberOfLoops = 2
            loopDuration = 0.5

        anim2 Animation {withKey: "in"}:
            numberOfLoops = 3
            loopDuration = 1.5
        

    var tproxy = TestProxy.new(nodeForTest())
    echo "node name ", tproxy.node.name, " Text comp text ", tproxy.text.text, " intval ", tproxy.source

    nodeProxy TestProxy2 of TestProxy:
        someOtherNode Node {withName: "someothernode"}:
            enabled = false

    var tproxy2 = new(TestProxy2, nodeForTest())
    echo "node name ", tproxy2.node.name, " Text comp text ", tproxy2.text.text, " intval ", tproxy2.source, " newprop.enabled ", tproxy2.someOtherNode.enabled
