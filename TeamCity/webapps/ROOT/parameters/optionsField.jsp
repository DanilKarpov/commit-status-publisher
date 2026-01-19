<%@include file="/include-internal.jsp"%>
<jsp:useBean id="context" scope="request" type="jetbrains.buildServer.controllers.parameters.ParameterRenderContext"/>
<jsp:useBean id="options" scope="request" type="java.util.Collection< jetbrains.buildServer.controllers.parameters.types.SelectParameterTypeBase.KeyValue >"/>

<c:set var="selectedKey" value="${context.parameter.value}"/>
<forms:select disabled="${context.readOnly}" name="${context.id}" id="${context.id}" style="width:100%">
  <c:set var="hasSelected" value="${false}"/>
   <c:forEach var="it" items="${options}">
     <c:set var="selected" value="${it.key eq selectedKey}"/>
     <c:if test="${selected}"><c:set var="hasSelected" value="${true}"/></c:if>
     <forms:option disabled="${context.readOnly}" value="${it.key}" selected="${selected}"><c:out value="${it.value}"/></forms:option>
   </c:forEach>
 </forms:select>
