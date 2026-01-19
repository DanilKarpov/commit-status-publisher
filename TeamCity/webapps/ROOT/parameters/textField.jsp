<%@include file="/include-internal.jsp"%>
<jsp:useBean id="context" scope="request" type="jetbrains.buildServer.controllers.parameters.ParameterRenderContext"/>

<forms:textField disabled="${context.readOnly}" expandable="${true}" name="${context.id}" id="${context.id}" value="${context.parameter.value}" className="buildTypeParams textProperty longField"/>
