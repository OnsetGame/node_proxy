import node_proxy / proxy
import rod / [rod_types, viewport, node, component]
import rod / component / text_component
import nimx / animation
import observarble

type CustomType = ref object
    field: string
let customInstance = CustomType()

observarble MyObservarble:
    name string

var n = newNode("root")
let child1 = n.newChild("child1name")
let child2 = n.newChild("child2name")

let t1 = n.component(Text)
let t2 = child1.component(Text)

var a1 = newAnimation()
a1.loopDuration = 1.0
a1.numberOfLoops = 10
n.registerAnimation("nodekey", a1)

var a2 = newAnimation()
a2.loopDuration = 1.0
a2.numberOfLoops = 10
child1.registerAnimation("child1key", a2)


nodeProxy MyProxy1:
    # Define property of any type
    intfield1 int
    floatfield1 float
    custonfield1 CustomType

    # Define property and init it with value
    intfield2 int {withValue: 100}
    floatfield2 float {withValue: 100.0}
    custonfield2 CustomType {withValue: customInstance}

    # Define property and init it with value - result of proc
    intfield3 int {withValue: proc(np: MyProxy1): int = 100}
    floatfield3 float {withValue: proc(np: MyProxy1): float = 100.0}
    custonfield3 CustomType {withValue: proc(np: MyProxy1): CustomType = 
        result = CustomType()
        result.field = "newval"
    }

    # Define property as public
    intfield4* int
    floatfield4* float
    custonfield4* CustomType


nodeProxy MyProxy2:
    # Find node in depth with name `child1name`
    child1* Node {withName: "child1name"}

    # Add node to child1 as node with name `child2`
    child2* Node {addTo: child1}

    # Add node to parent node as node with name `child3`
    child3* Node {addTo: node}

    # Add node to parent child1 as node with name `mychild`
    child4* Node {addTo: child1, withName: "mychild4"}
    
    # Set properties of the node
    child5* Node {addTo: child1, withName: "mychild5"}:
        enabled = false
        alpha = 0.0
    
    # Call methods of the node
    child6* Node {addTo: child1, withName: "mychild6"}:
        removeFromParent()


nodeProxy MyProxy3:
    child1 Node {withName: "child1name"}
    child2* Node {addTo: node}
    child3* Node {addTo: node}

    # Get component on root node
    textcomp1 Text {onNode: node}

    # Get component on child node with name "child1name"
    textcomp2 Text {onNode: "child1name"}

    # Get component on child1 node
    textcomp3 Text {onNode: child1}

    # Add component
    textcomp4 Text {onNodeAdd: child2}

    # Setup component 
    textcomp5 Text {onNodeAdd: child3}:
        text = "Text"
        fontSize = 32.0


nodeProxy MyProxy4:
    child1 Node {withName: "child1name"}

    # Animation with key `nodekey` attached on root node
    anim1 Animation {withKey: "nodekey"}

    # Animation with key `child1key` attached on child1 node
    anim2 Animation {withKey: "child1key", forNode: child1}

    # Animation with key `child1key` attached on node with name `child1name`
    anim3 Animation {withKey: "child1key", forNode: "child1name"}

    # Setup animation
    anim4 Animation {withKey: "nodekey"}:
        loopDuration = 2.0
        numberOfLoops = 5
        onAnimate = proc(p: float) =
            np.node.alpha = 1.0 - p


nodeProxy MyProxy5:
    obj MyObservarble

    # Define component and setup observarble. Code in the body will be executed only on obj will notify 
    textcomp1 Text {onNode: node, observe: obj}:
        text = np.obj.name

    # Define component, setup component and setup observer
    textcomp2 Text:
        # The body will be executed on init broxy
        {onNode: "child1name"}:
            fontSize = 34.0
        # The body will be executed only on obj will notify 
        {observe: obj}:
            text = np.obj.name


let proxy1 = MyProxy1.new(n)
let proxy2 = MyProxy2.new(n)
let proxy3 = MyProxy3.new(n)
let proxy4 = MyProxy4.new(n)
let proxy5 = MyProxy5.new(n)
# let obj = MyObservarble.new()
# proxy5.obj = obj