import rod / [component, node]
import observarble


type ObserverComponent* = ref object of Component
    target*: Observarble
    subscriptions*: seq[ObserverHandler]
    added: bool

method componentNodeWasAddedToSceneView*(c: ObserverComponent) = 
    for cb in c.subscriptions:
        c.target.subscribe(c, cb)
    c.added = true

method componentNodeWillBeRemovedFromSceneView*(c: ObserverComponent) = 
    c.target.unsubscribe(c)
    c.added = false

proc subscribe*(c: ObserverComponent, cb: ObserverHandler) =
    if c.subscriptions.isNil:
        c.subscriptions = @[]
    c.subscriptions.add(cb)
    if c.added:
        c.target.subscribe(c, cb)

proc subscribe*(c: ObserverComponent, cb: openarray[ObserverHandler]) =
    if c.subscriptions.isNil:
        c.subscriptions = @[]
    c.subscriptions.add(cb)
    if c.added:
        for cc in cb:
            c.target.subscribe(c, cc)

registerComponent(ObserverComponent, "Observarble")


proc subscribe*(n: Node, o: Observarble, cb: ObserverHandler) =
    for comp in n.components:
        if comp of ObserverComponent:
            let c = comp.ObserverComponent
            if c.target == o:
                c.subscribe(cb)
                return

    let comp = n.addComponent(ObserverComponent)
    comp.target = o
    comp.subscribe(cb)

proc subscribe*(n: Node, o: Observarble, cbs: openarray[ObserverHandler]) =
    for cb in cbs:
        n.subscribe(o, cb)

proc unsubscribe*(n: Node, o: Observarble) =
    for comp in n.components:
        if comp of ObserverComponent:
            let c = comp.ObserverComponent
            if c.target == o:
                n.removeComponent(c)
                return