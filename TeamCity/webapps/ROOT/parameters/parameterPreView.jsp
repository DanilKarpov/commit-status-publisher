<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@include file="/include-internal.jsp"%>
<jsp:useBean id="parameterConstants" class="jetbrains.buildServer.controllers.parameters.ParameterConstants" />

<jsp:useBean id="context" scope="request" type="jetbrains.buildServer.controllers.parameters.ParameterRenderContext"/>
<jsp:useBean id="label" scope="request" type="java.lang.String"/>

<div id="${context.id}_container" class="parameter non_serializable_form_elements_container custom_container_control_${context.id}">
  <bs:trim maxlength="45">${label}</bs:trim>:
  <strong><c:out value="${context.parameter.value}"/></strong>
</div>
