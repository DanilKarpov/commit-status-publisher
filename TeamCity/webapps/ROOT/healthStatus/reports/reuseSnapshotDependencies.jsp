<%@ page import="jetbrains.buildServer.controllers.admin.projects.BuildConfigurationSteps" %>
<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="targetBuildType" value="${healthStatusItem.additionalData['targetBuildType']}"/>
<c:set var="dependentBuildType" value="${healthStatusItem.additionalData['dependentBuildType']}"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>

<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="cameFromUrl" value="${showMode eq inplaceMode ? pageUrl : healthStatusReportUrl}"/>

<c:choose>
  <c:when test="${fn:startsWith(healthStatusItem.identity, 'buildsReusingBadVcsSettings')}">
    <admin:viewOrEditBuildTypeLinkFull buildType="${dependentBuildType}" step="<%=BuildConfigurationSteps.DEPENDENCIES_STEP_ID%>"/>
    has snapshot dependency on <admin:viewOrEditBuildTypeLinkFull buildType="${targetBuildType}"/>
    with suitable builds reusing enabled, but settings of the following VCS roots prevent builds reusing:<bs:help file="Snapshot Dependencies" anchor="SuitableBuilds"/>
    <ul>
      <c:forEach items="${healthStatusItem.additionalData['badVcsRoots']}" var="vcsRoot">
        <li><admin:vcsRootName vcsRoot="${vcsRoot.parent}" editingScope="" cameFromUrl="${cameFromUrl}"/></li>
      </c:forEach>
    </ul>
  </c:when>
  <c:when test="${fn:startsWith(healthStatusItem.identity, 'buildsReusingSettingsConflict')}">
    Builds might not be reused because of inconsistent snapshot dependency settings:<bs:help file="Snapshot Dependencies"/>
    <ul>
      <li>
        <admin:editBuildTypeLinkFull buildType="${dependentBuildType}" step="<%=BuildConfigurationSteps.DEPENDENCIES_STEP_ID%>"/>
        depends on <admin:viewOrEditBuildTypeLinkFull buildType="${targetBuildType}"/> (suitable builds reusing <strong>enabled</strong>)
      </li>
      <c:forEach items="${healthStatusItem.additionalData['buildTypesWithReuseDisabled']}" var="bt">
        <li>
          <c:choose>
            <c:when test="${afn:permissionGrantedForBuildType(bt, 'EDIT_PROJECT')}">
              <admin:viewOrEditBuildTypeLinkFull buildType="${bt}" step="<%=BuildConfigurationSteps.VCS_SETTINGS_STEP_ID%>"/>
            </c:when>
            <c:when test="${afn:permissionGrantedForBuildType(bt, 'VIEW_PROJECT')}">
              <admin:viewOrEditBuildTypeLinkFull buildType="${bt}"/>
            </c:when>
            <c:otherwise><em>inaccessible build configuration</em></c:otherwise>
          </c:choose>
          depends on <admin:viewOrEditBuildTypeLinkFull buildType="${targetBuildType}"/> (suitable builds reusing <strong>disabled</strong>)
        </li>
      </c:forEach>
    </ul>
  </c:when>

  <c:when test="${fn:startsWith(healthStatusItem.identity, 'dangerousReuseDependency')}">

    <admin:viewOrEditBuildTypeLinkFull buildType="${dependentBuildType}" step="<%=BuildConfigurationSteps.DEPENDENCIES_STEP_ID%>"/>
    has a snapshot dependency on <admin:viewOrEditBuildTypeLinkFull buildType="${targetBuildType}" step="<%=BuildConfigurationSteps.BUILD_STEPS_STEP_ID%>"/>
    with enabled build re-use.

    <p>The dependency build configuration contains a build step(s) with <strong>agent runtime parameters</strong> in its execution conditions.</p>

    <p>In combination with the <a href="<bs:helpUrlPrefix/>Build+Dependencies+Setup#Reusing+builds">build reuse</a>
      option enabled for the dependent build configuration, this might result in unexpected source reuse in the current build chain.</p>

    <p>Consider disabling the "Do not run new build if there is a suitable one" option in snapshot dependencies of the current build configuration.</p>

  </c:when>
</c:choose>


