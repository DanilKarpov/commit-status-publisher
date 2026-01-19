<%@ page import="jetbrains.buildServer.controllers.parameters.types.CheckboxFieldParameterType" %>
<%@include file="/include-internal.jsp"%>
<jsp:useBean id="context" scope="request" type="jetbrains.buildServer.controllers.parameters.ParameterRenderContext"/>
<jsp:useBean id="checkboxChecked" scope="request" type="java.lang.Boolean"/>
<jsp:useBean id="checkedValue" scope="request" type="java.lang.String"/>
<c:if test="${empty checkedValue}">
  <c:set var="checkedValue" value="<%=CheckboxFieldParameterType.EMPTY_CHECKED_VAL_PLACEHOLDER%>"/>
</c:if>

<div>
  <forms:checkbox disabled="${context.readOnly}" name="${context.id}" id="${context.id}" checked="${checkboxChecked}" style="width:auto;"/>
  <c:set var="label" value="${context.description.parameterTypeArguments['text']}"/>
  <c:if test="${not empty label}">
    <label for="${context.id}"><c:out value="${label}"/></label>
  </c:if>
</div>

<ext:registerTypedParameterScript context="${context}">
{
  getControlValue: function() {
    return $('${context.id}').checked ? '<bs:escapeForJs text="${checkedValue}"/>' : null;
  }
}
</ext:registerTypedParameterScript>