<%@ include file="/include-internal.jsp"
%><jsp:useBean id="serverTC" type="jetbrains.buildServer.serverSide.SBuildServer" scope="request"
/><c:set var="projectBeans" value="${overviewBean.overviewProjectBeans}"
/><div id="buildTypes">
  <c:if test="${intprop:getBoolean('teamcity.ui.experimental.switchAvailable') && ufn:booleanPropertyValue(currentUser, 'teamcity.ui.experimental.overview')}">
    <style type="text/css">
      .tableCaption table.runTable td.pendingMessage{
        text-align: left !important;
      }
      .tableCaption {
        border-top: none !important;
      }
    </style>
  </c:if>
  <c:if test="${empty projectBeans}">
    <c:set var="noProjectsReason" value="${overviewBean.overviewIsEmptyReason}"/>
    <c:if test="${noProjectsReason == 'NO_PROJECTS_IN_SYSTEM'}">
      <authz:authorize allPermissions="CREATE_SUB_PROJECT" projectId="${overviewBean.rootProject.projectId}">
        <p>There are no projects in TeamCity. To start running builds, create projects and build configurations first.</p>
        <c:if test="${not overviewBean.rootProject.readOnly and overviewBean.rootProject.projectCreateSupported}">
          <admin:createProjectButtons parentProject="${overviewBean.rootProject}" cameFromUrl="${pageUrl}" defaultCreateMode="createFromUrl"/>
        </c:if>
      </authz:authorize>
      <authz:authorize allPermissions="CHANGE_SERVER_SETTINGS, MANAGE_SERVER_LICENSES, CREATE_USER">
        <p class="indented-paragraph">You may also want to:</p>
        <ul class="startPage">
          <li><a href="<c:url value='/admin/admin.html?item=email'/>">configure email settings</a> to enable notifications,</li>
          <li><a href="<c:url value='/admin/admin.html?item=license'/>">manage licenses</a>, and</li>
          <li><a href="<c:url value='/admin/admin.html?item=users'/>">add more users to TeamCity</a>.</li>
        </ul>
      </authz:authorize>
    </c:if>

    <c:if test="${noProjectsReason == 'NO_VISIBLE_PROJECTS' or noProjectsReason == 'VISIBLE_PROJECTS_ARCHIVED'}">
      <p>
        There are no projects to show.
        <c:if test="${!isSpecialUser}">
        <authz:authorize allPermissions="CHANGE_OWN_PROFILE">
          Please <a href="#" onclick="BS.VisibleProjectsDialog.show(); return false">configure visible projects</a>.
        </authz:authorize>
        </c:if>
      </p>
    </c:if>

    <c:if test="${noProjectsReason == 'SUCCESSFUL_HIDDEN'}">
        <%@ include file="_someSuccessfulHiddenNote.jspf" %>
    </c:if>

    <c:if test="${noProjectsReason == 'UNKNOWN_REASON'}">
      <p class="indented-paragraph">There are no projects to show. Possible reasons:</p>
      <ul class="startPage">
        <c:if test="${!isSpecialUser}">
        <authz:authorize allPermissions="CHANGE_OWN_PROFILE">
          <li>You should <a href="#" onclick="BS.VisibleProjectsDialog.show(); return false">configure visible projects</a></li>
        </authz:authorize>
        </c:if>
        <li>You do not have enough permissions to view projects</li>
        <li>TeamCity server administrators have not configured any projects</li>
      </ul>
    </c:if>

    <authz:authorize anyPermission="CHANGE_SERVER_SETTINGS, MANAGE_SERVER_LICENSES, CREATE_USER">
      <jsp:attribute name="ifAccessDenied">
        <c:choose>
          <c:when test="${noProjectsReason == 'NO_PROJECTS_IN_SYSTEM'}">
            <p>There are no projects in TeamCity. Please contact your system administrator.</p>
          </c:when>
          <c:when test="${noProjectsReason == 'NO_ACCESSIBLE_PROJECTS'}">
            <p>There are no projects to show, because you don't have permissions to view projects. Please contact your system administrator.</p>
          </c:when>
        </c:choose>
      </jsp:attribute>
    </authz:authorize>
  </c:if
  ><bs:messages key="buildNotFound"
 /><bs:messages key="buildTypeNotFound"
 /><bs:messages key="changeNotFound"
 /><bs:messages key="projectNotFound"
 /><bs:messages key="visibleProjectsSaved"
 /><div class="clr"></div>

  <c:set var="runningAndQueuedBuilds" value="${overviewBean.runningBuildsModel}" scope="request"
  /><c:set var="problemsSummary" value="${overviewBean.problemsSummary.countersMap}" scope="request"
  /><c:if test="${not empty projectBeans}"
      ><c:url var="url" value="/overview.html"
     /><bs:refreshable containerId="overviewMain" pageUrl="${url}"
      ><c:forEach var="item" items="${projectBeans}" varStatus="status"
        ><c:set var="projectBean" value="${item}" scope="request"
        /><jsp:include page="/projectBuildTypes.jsp"><jsp:param name="child_project" value="true"/></jsp:include></c:forEach
    ></bs:refreshable
  ></c:if
><bs:executeOnce id="pauseDialog"><bs:pauseBuildTypeDialog/></bs:executeOnce
></div>