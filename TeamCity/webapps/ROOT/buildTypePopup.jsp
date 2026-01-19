<%@ include file="include-internal.jsp"
%><jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.SBuildType" scope="request"
/><jsp:useBean id="branch" type="java.lang.String" scope="request"
/><jsp:useBean id="buildTypeTabs" type="java.util.List" scope="request"
/><jsp:useBean id="withProject" type="java.lang.Boolean" scope="request"
/><jsp:useBean id="withAdmin" type="java.lang.Boolean" scope="request"
/><jsp:useBean id="withResponsibility" type="java.lang.Boolean" scope="request"

/><c:set var="projectExternalId" value="${buildType.projectExternalId}"/>
<c:set var="buildTypeExternalId" value="${buildType.externalId}"/>
<c:set var="branchParam" value=""
/><c:if test="${not empty branch}">
  <c:set var="branchParam">&branch_${projectExternalId}=<bs:forUrl val="${branch}"/></c:set>
</c:if
><div class="summaryContainer">
  <ul class="menuList menuListGrouped">
    <c:if test="${withProject}">
      <c:url value='/project.html?projectId=${projectExternalId}${branchParam}' var="projectUrl"/>
      <li>
        <a href="${projectUrl}" title="Project home page">Project Home</a>
      </li>
      <li class="menuListSeparator"></li>
    </c:if>

    <c:forEach var="tab" items="${buildTypeTabs}">
      <c:url value='/viewType.html?buildTypeId=${buildTypeExternalId}&tab=${tab.tabId}${branchParam}' var="url"/>
      <li>
        <a href="${url}">${tab.tabTitle}</a>
      </li>
    </c:forEach>

    <c:if test="${withResponsibility}">
      <li class="menuListSeparator"></li>
      <li>
        <a href="#" onclick="BS.ResponsibilityDialog.showDialog('${buildTypeExternalId}', '<c:out value="${buildType.name}"/>'); return false;"
           title="Assign a user to investigate problems in the configuration">Assign investigation...</a>
      </li>
    </c:if>

    <c:if test="${withAdmin}">
      <li class="menuListSeparator"></li>
      <li>
        <admin:editBuildTypeLink buildTypeId="${buildTypeExternalId}"
                                 title="Edit build configuration settings">Edit Settings</admin:editBuildTypeLink>
      </li>
    </c:if>
  </ul>
</div>