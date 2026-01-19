<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="currentValue" type="jetbrains.buildServer.controllers.admin.projects.ValueResolverController.ResolvedValue" scope="request"/>
<jsp:useBean id="otherValues" type="java.util.List" scope="request"/>
<style type="text/css">
table.resolvedValues td {
  padding: 2px;
  vertical-align: top;
}

table.resolvedValues td.resolveContext {
  padding-right: 12px;
}

table.resolvedValues td.resolvedValue span.value {
  white-space: pre-wrap;
}
</style>
<c:set var="contextProject" value=""/>
<c:choose>
  <c:when test="${not empty currentValue.project}"><c:set var="contextProject" value="${currentValue.project}"/></c:when>
  <c:when test="${not empty currentValue.buildType}"><c:set var="contextProject" value="${currentValue.buildType.project}"/></c:when>
  <c:when test="${not empty currentValue.buildTypeTemplate}"><c:set var="contextProject" value="${currentValue.buildTypeTemplate.project}"/></c:when>
</c:choose>
<table class="runnerFormTable resolvedValues">
  <tr>
    <c:if test="${not empty otherValues}">
    <td class="resolveContext">
      <c:choose>
        <c:when test="${not empty currentValue.project}"><bs:projectOrBuildTypeIcon type="project"/> <strong><admin:editProjectLinkFull project="${currentValue.project}" contextProject="${contextProject}"/></strong>:</c:when>
        <c:when test="${not empty currentValue.buildType}"><bs:projectOrBuildTypeIcon type="buildType" composite="${currentValue.buildType.compositeBuildType}"/> <strong><admin:editBuildTypeLinkFull buildType="${currentValue.buildType}" contextProject="${contextProject}"/></strong>:</c:when>
        <c:when test="${not empty currentValue.buildTypeTemplate}"><bs:projectOrBuildTypeIcon type="template"/> <strong><admin:editTemplateLinkFull template="${currentValue.buildTypeTemplate}" contextProject="${contextProject}"/></strong>:</c:when>
      </c:choose>
    </td>
    </c:if>
    <td class="resolvedValue">
      <c:choose>
        <c:when test="${empty currentValue.resolvedValue}"><em>&lt;empty&gt;</em></c:when>
        <c:otherwise>
          <span class="value"><c:out value="${currentValue.resolvedValue}"/></span>
        </c:otherwise>
      </c:choose>
    </td>
  </tr>
  <c:set var="prevValue" value="${currentValue.resolvedValue}"/>
  <c:forEach items="${otherValues}" var="val">
    <c:if test="${currentValue ne val}">
      <tr>
        <td class="resolveContext">
          <c:choose>
            <c:when test="${not empty val.project}"><bs:projectOrBuildTypeIcon type="project"/> <admin:editProjectLinkFull project="${val.project}" contextProject="${contextProject}"/>:</c:when>
            <c:when test="${not empty val.buildType}"><bs:projectOrBuildTypeIcon type="buildType" composite="${val.buildType.compositeBuildType}"/> <admin:editBuildTypeLinkFull buildType="${val.buildType}" contextProject="${contextProject}"/>:</c:when>
            <c:when test="${not empty val.buildTypeTemplate}"><bs:projectOrBuildTypeIcon type="template"/> <admin:editTemplateLinkFull template="${val.buildTypeTemplate}" contextProject="${contextProject}"/>:</c:when>
          </c:choose>
        </td>
        <td class="resolvedValue">
          <c:choose>
            <c:when test="${empty val.resolvedValue}"><em>&lt;empty&gt;</em></c:when>
            <c:when test="${prevValue ne val.resolvedValue}">
              <span class="value"><c:out value="${val.resolvedValue}"/></span>
            </c:when>
            <c:otherwise><em>&lt;same as above&gt;</em></c:otherwise>
          </c:choose>
          <c:set var="prevValue" value="${val.resolvedValue}"/>
        </td>
      </tr>
    </c:if>
  </c:forEach>
</table>