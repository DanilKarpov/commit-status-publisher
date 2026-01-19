<%@ page import="java.util.Date" %>
<%@include file="/include-internal.jsp"%>
<div>
  Entities changes in memory, but not persisted to disk
</div>

<c:if test="${not empty projects}">
  <div>
    <b>Projects</b>
    <c:set var="entityType" value="project"/>
    <c:forEach var="item" items="${projects}">
      <div>
        <admin:editProjectLink projectId="${item['entity'].externalId}"><bs:out value="${item['entity'].fullName}"/></admin:editProjectLink>
        <%@ include file="notPersistedEntityDetails.jspf" %>
      </div>
    </c:forEach>
  </div>
</c:if>

<c:if test="${not empty buildTypes}">
  <div>
    <b>Build configurations</b>
    <c:set var="entityType" value="buildType"/>
    <c:forEach var="item" items="${buildTypes}">
      <div>
        <admin:editBuildTypeLink buildTypeId="${item['entity'].externalId}"><bs:out value="${item['entity'].fullName}"/></admin:editBuildTypeLink>
        <%@ include file="notPersistedEntityDetails.jspf" %>
      </div>
    </c:forEach>
  </div>
</c:if>

<c:if test="${not empty templates}">
  <div>
    <b>Build templates</b>
    <c:set var="entityType" value="template"/>
    <c:forEach var="item" items="${templates}">
      <div>
        <admin:editTemplateLink templateId="${item['entity'].externalId}"><bs:out value="${item['entity'].fullName}"/></admin:editTemplateLink>
        <%@ include file="notPersistedEntityDetails.jspf" %>
      </div>
    </c:forEach>
  </div>
</c:if>

<c:if test="${not empty vcsRoots}">
  <div>
    <b>Vcs roots</b>
    <c:set var="entityType" value="vcsRoot"/>
    <c:forEach var="item" items="${vcsRoots}">
      <div>
        <admin:editVcsRootLink vcsRoot="${item['entity']}" editingScope="" cameFromUrl="${pageUrl}"><bs:out value="${item['entity'].name}"/></admin:editVcsRootLink>
        <%@ include file="notPersistedEntityDetails.jspf" %>
      </div>
    </c:forEach>
  </div>
</c:if>

