<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="modification" scope="request" type="jetbrains.buildServer.vcs.SVcsModification"/>
<%--@elvariable id="showMode" type=""--%>
<c:url value="/downloadPatch.html" var="patchUrl">
  <c:param name="buildTypeId" value="${not empty buildType ? buildType.buildTypeId : ''}"/>
  <c:param name="modId" value="${modification.id}"/>
  <c:param name="personal" value="${modification.personal}"/>
</c:url>
<c:choose>
  <c:when test="${showMode == 'compact'}">
    <a class="noUnderline" href="${patchUrl}" title="Download patch"><i class="tc-icon icon16 tc-icon_patch"></i></a><bs:openPatchIde patchUrl="${patchUrl}" showMode="${showMode}"/>
  </c:when>
  <c:otherwise>
    <dt>
      <i class="tc-icon icon16 tc-icon_patch" title="Download patch"></i>
      <a href="${patchUrl}">Download patch</a></dt>
    <dt><bs:openPatchIde patchUrl="${patchUrl}" showMode="${showMode}"/></dt>
  </c:otherwise>
</c:choose>
