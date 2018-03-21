[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2FOnsetGame%2Fnode_proxy.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2FOnsetGame%2Fnode_proxy?ref=badge_shield)

node_proxy - Node proxy is an ORM for rod nodes
===============================================

*NOTE:* Use `-d:debugNodeProxy` to see macro output 


1. Define any properties
------------------------

.. code-block:: nim

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


Generated Code
~~~~~~~~~~~~~~

.. code-block:: nim

    type
        MyProxy1* = ref object of NodeProxy
            intfield1: int
            floatfield1: float
            custonfield1: CustomType
            intfield2: int
            floatfield2: float
            custonfield2: CustomType
            intfield3: int
            floatfield3: float
            custonfield3: CustomType
            intfield4*: int
            floatfield4*: float
            custonfield4*: CustomType

        proc init*(np: MyProxy1; node2076067: Node) =
            np.NodeProxy.init(node2076067)
            np.intfield2 = 100
            np.floatfield2 = 100.0
            np.custonfield2 = customInstance
            block:
                let ctor2076069 = proc (np: MyProxy1): int =
                    100
                np.intfield3 = ctor2076069(np)
            block:
                let ctor2076071 = proc (np: MyProxy1): float =
                    100.0
                np.floatfield3 = ctor2076071(np)
            block:
                let ctor2076073 = proc (np: MyProxy1): CustomType =
                    result = CustomType()
                    result.field = "newval"
                np.custonfield3 = ctor2076073(np)

    proc new*(T: typedesc[MyProxy1]; node2076075: Node): T =
        result = T.new()
        result.init(node2076075)


2. Work with nodes
------------------

.. code-block:: nim

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


Generated Code
~~~~~~~~~~~~~~

.. code-block:: nim

    type
        MyProxy2* = ref object of NodeProxy
            child1*: Node
            child2*: Node
            child3*: Node
            child4*: Node
            child5*: Node
            child6*: Node

    proc init*(np: MyProxy2; node2076146: Node) =
        np.NodeProxy.init(node2076146)
        np.child1 = np.node.findNode("child1name")
        np.child2 = np.child1.newChild("child2")
        np.child3 = np.node.newChild("child3")
        np.child4 = np.child1.newChild("mychild4")
        np.child5 = np.child1.newChild("mychild5")
        np.child5.enabled = false
        np.child5.alpha = 0.0
        np.child6 = np.child1.newChild("mychild6")
        np.child6.removeFromParent()

    proc new*(T: typedesc[MyProxy2]; node2076148: Node): T =
        result = T.new()
        result.init(node2076148)


3. Work with components
-----------------------

.. code-block:: nim

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


Generated Code
~~~~~~~~~~~~~~

.. code-block:: nim

    type
        MyProxy3* = ref object of NodeProxy
            child1: Node
            child2*: Node
            child3*: Node
            textcomp1: Text
            textcomp2: Text
            textcomp3: Text
            textcomp4: Text
            textcomp5: Text

    proc init*(np: MyProxy3; node2076183: Node) =
        np.NodeProxy.init(node2076183)
        np.child1 = np.node.findNode("child1name")
        np.child2 = np.node.newChild("child2")
        np.child3 = np.node.newChild("child3")
        np.textcomp1 = np.node.getComponent(Text)
        assert(np.textcomp1.isNil != true, "Component nil")
        np.textcomp2 = np.node.findNode("child1name").getComponent(Text)
        assert(np.textcomp2.isNil != true, "Component nil")
        np.textcomp3 = np.child1.getComponent(Text)
        assert(np.textcomp3.isNil != true, "Component nil")
        assert(np.child2.getComponent(Text).isNil, "Component already added")
        np.textcomp4 = np.child2.component(Text)
        assert(np.child3.getComponent(Text).isNil, "Component already added")
        np.textcomp5 = np.child3.component(Text)
        np.textcomp5.text = "Text"
        np.textcomp5.fontSize = 32.0

    proc new*(T: typedesc[MyProxy3]; node2076185: Node): T =
        result = T.new()
        result.init(node2076185)


4. Work with animations
-----------------------

.. code-block:: nim

    nodeProxy MyProxy4:
        child1 Node {withName: "child1name"}

        # Animation with key `nodekey` attached on root node
        anim1 Animation {withKey: "nodekey"}

        # Animation with key `child1key` attached on child1 node
        anim2 Animation {withKey: "nodekey", forNode: child1}

        # Animation with key `child1key` attached on node with name `child1name`
        anim3 Animation {withKey: "nodekey", forNode: "child1name"}

        # Setup animation
        anim4 Animation {withKey: "nodekey"}:
            loopDuration = 2.0
            numberOfLoops = 5
            onAnimate = proc(p: float) =
                np.node.alpha = 1.0 - p


Generated Code
~~~~~~~~~~~~~~

.. code-block:: nim

    type
        MyProxy4* = ref object of NodeProxy
            child1: Node
            anim1: Animation
            anim2: Animation
            anim3: Animation
            anim4: Animation

    proc init*(np: MyProxy4; node2077230: Node) =
        np.NodeProxy.init(node2077230)
        np.child1 = np.node.findNode("child1name")
        np.anim1 = np.node.animationNamed("nodekey")
        assert(np.anim1.isNil != true, "Animation nil")
        np.anim2 = np.child1.animationNamed("nodekey")
        assert(np.anim2.isNil != true, "Animation nil")
        np.anim3 = np.node.findNode("child1name").animationNamed("nodekey")
        assert(np.anim3.isNil != true, "Animation nil")
        np.anim4 = np.node.animationNamed("nodekey")
        assert(np.anim4.isNil != true, "Animation nil")
        np.anim4.loopDuration = 2.0
        np.anim4.numberOfLoops = 5
        np.anim4.onAnimate = proc (p: float) =
            np.node.alpha = 1.0 - p

    proc new*(T: typedesc[MyProxy4]; node2077232: Node): T =
        result = T.new()
        result.init(node2077232)


5. Work with observarbles
-------------------------

.. code-block:: nim

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


Generated Code
~~~~~~~~~~~~~~

.. code-block:: nim

    type
        MyProxy5* = ref object of NodeProxy
            observed_obj: MyObservarble
            textcomp1: Text
            textcomp2: Text

    template onUpdateObserved_obj(np: MyProxy5) =
        np.textcomp1.text = np.obj.name
        np.textcomp2.text = np.obj.name

    proc obj(np: MyProxy5): MyObservarble =
        np.observed_obj

    proc `obj=`(np: MyProxy5; obj: MyObservarble) =
        if not(np.observed_obj.isNil):
            for c2078027 in np.node.components:
            if c2078027 of ObserverComponent and
                (c2078027.ObserverComponent.target ==
                np.observed_obj):
                np.node.removeComponent(c2078027)
                break
        np.observed_obj = obj
        if not(np.observed_obj.isNil):
            let c2078029 = np.node.addComponent(ObserverComponent)
            c2078029.target = np.observed_obj
            c2078029.subscribe(proc (obj: Observarble) =
            np.onUpdateObserved_obj())
            np.onUpdateObserved_obj()

    proc init*(np: MyProxy5; node2078025: Node) =
        np.NodeProxy.init(node2078025)
        np.textcomp1 = np.node.getComponent(Text)
        assert(np.textcomp1.isNil != true, "Component nil")
        np.textcomp2 = np.node.findNode("child1name").getComponent(Text)
        assert(np.textcomp2.isNil != true, "Component nil")
        np.textcomp2.fontSize = 34.0

    proc new*(T: typedesc[MyProxy5]; node2078031: Node): T =
        result = T.new()
        result.init(node2078031)


6. Environment for the code above
---------------------------------

.. code-block:: nim

    import node_proxy / proxy
    import rod / component / text_component
    import observarble

    type CustomType = ref object
        field: string
    let customInstance = CustomType()

    observarble MyObservarble:
        name: string

    var node = newNode("root")
    let child1 = node.newChild("child1name")
    let child2 = node.newChild("child2name")

    let t1 = node.component(Text)
    let t2 = child1.component(Text)

    var a1 = newAnimation()
    a1.loopDuration = 1.0
    a1.numberOfLoops = 10
    node.registerAnimation("nodekey", a1)

    var a2 = newAnimation()
    a2.loopDuration = 1.0
    a2.numberOfLoops = 10
    child1.registerAnimation("child1key", a2)

    let proxy1 = MyProxy1.new(node)
    let proxy2 = MyProxy2.new(node)
    let proxy3 = MyProxy3.new(node)
    let proxy4 = MyProxy4.new(node)
    let proxy5 = MyProxy5.new(node)
    let obj = MyObservarble.new()
    proxy5.obj = obj


## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2FOnsetGame%2Fnode_proxy.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2FOnsetGame%2Fnode_proxy?ref=badge_large)