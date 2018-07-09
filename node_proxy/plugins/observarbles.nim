import macros, tables, strutils
import .. / plugin
import rod / component
import observarble
import observarble_component


proc observeProxyPlugin*(data: NodeProxyPluginData) =
    data.checkArgs()

    let T = data.T
    let target = data.props["observe"]
    target.expectKind(nnkIdent)

    let pTarget = ident("observed_" & $target.ident)
    let updaterName = ident("onUpdateObserved_" & $target.ident)
    
    let recList = data.body.getTypeSection().getRecListFor($data.T.ident)
    for i, rec in recList:
        let n = rec.getPropNameIdent()
        if n == target:
            let targetType = rec.getPropTypeIdent()
            var isPublic = rec.isPublic()
            rec[0] = pTarget
            
            let updater = quote:
                template `updaterName`(`NP`: `T`) =
                    discard
            updater[6] = nnkStmtList.newTree()
            for x in data.propBody:
                updater[6].add(x)
            data.body.add(updater)

            let getterName = if isPublic: nnkPostfix.newTree(ident("*"), target) else: target
            let getter = quote:
                proc `getterName`(`NP`: `T`): `targetType` = `NP`.`pTarget`
            data.body.add(getter)

            let setterName = if isPublic: nnkPostfix.newTree(ident("*"), nnkAccQuoted.newTree(ident($target.ident & "="))) else: nnkAccQuoted.newTree(ident($target.ident & "="))
            let setter = quote:
                proc `setterName`(`NP`: `T`, `target`: `targetType`) =
                    if not (`NP`.`pTarget`.isNil):
                        for c in `NP`.node.components:
                            if c of ObserverComponent and c.ObserverComponent.target == `NP`.`pTarget`:
                                `NP`.node.removeComponent(c)
                                break
                    
                    `NP`.`pTarget` = `target`

                    if not (`NP`.`pTarget`.isNil):
                        let c = `NP`.node.addComponent(ObserverComponent)
                        c.target = `NP`.`pTarget`
                        c.subscribe(
                            proc() =
                                `NP`.`updaterName`()
                        )
                        `NP`.`updaterName`()
            data.body.add(setter)
        elif n == pTarget:
            for x in data.body:
                if x.kind == nnkTemplateDef:
                    var name = x[0]
                    if name.kind == nnkPostfix:
                        name = name[1]
                    if name == updaterName:
                        for y in data.propBody:
                            x[6].add(y)
                    break

    data.propBody = nil

static:
    registerPlugin("observe", observeProxyPlugin)