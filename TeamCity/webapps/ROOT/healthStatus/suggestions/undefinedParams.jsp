<%@ page import="jetbrains.buildServer.controllers.buildType.ParameterInfo" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.SBuildType" scope="request"/>
<c:set var="undefinedParams" value="${healthStatusItem.additionalData['undefinedParams']}"/>
<div class="suggestionItem">
  There <bs:are_is val="${fn:length(undefinedParams)}"/> <strong><c:out value="${fn:length(undefinedParams)}"/></strong>
  undefined parameter<bs:s val="${fn:length(undefinedParams)}"/> in <admin:editBuildTypeLinkFull buildType="${buildType}"/>:

  <c:set var="buildParamsLink"><admin:editBuildTypeLink buildTypeId="${buildType.externalId}" step="buildParams" withoutLink="true"/></c:set>

  <c:forEach items="${undefinedParams}" var="paramName">
    <c:set var="paramId" value='<%=ParameterInfo.makeParameterId((String)pageContext.getAttribute("paramName"))%>'/>
    <div>
      <forms:addLink href="${buildParamsLink}#edit_${paramId}">Define "<c:out value="${paramName}"/>"</forms:addLink>
    </div>
  </c:forEach>
</div>
