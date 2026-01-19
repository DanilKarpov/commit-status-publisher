<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@include file="/include-internal.jsp"%>

<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="outdatedProject" value="${healthStatusItem.additionalData['project']}"/>
<%--@elvariable id="outdatedProject" type="jetbrains.buildServer.serverSide.SProject"--%>
<%--@elvariable id="project" type="jetbrains.buildServer.serverSide.SProject"--%>
<c:set var="convertedSettings" value="${healthStatusItem.additionalData['convertedSettings']}"/>
<c:set var="configVersions" value="${healthStatusItem.additionalData['configVersions']}"/>
<c:set var="currentConfigsVersion" value="${healthStatusItem.additionalData['currentConfigsVersion']}"/>
<c:set var="detailsBlockId" value="outdatedProjectSettings_${showMode}_${outdatedProject.externalId}"/>
<%--@elvariable id="convertedSettings" type="java.util.List<jetbrains.buildServer.serverSide.impl.versionedSettings.ConvertedSettings>"--%>
<%--@elvariable id="configVersions" type="java.util.Map<jetbrains.buildServer.serverSide.SProject, String>"--%>
<%--@elvariable id="currentConfigsVersion" type="java.lang.String"--%>

<style type="text/css">
  .converterBlock {
    margin-left: 1em;
  }

  .affectedEntities {
    margin-top: 1em;
  }

  .converterSubj {
    margin-top: 0.5em;
    margin-left: 1em;
  }
</style>

<c:choose>
  <c:when test="${empty convertedSettings and not empty configVersions}">
    Please change the <bs:helpLink file="Upgrading+DSL" anchor="configsVersion">configs version</bs:helpLink> to "<c:out value="${currentConfigsVersion}"/>"

    <c:choose>
      <c:when test="${showMode == inplaceMode}">
        in
        <a href="javascript:;" onclick="$j('#${detailsBlockId}').toggle();"><bs:plural txt="project" val="${fn:length(configVersions)}"/> &raquo;</a>
        <div id="${detailsBlockId}" style="display: none">
          <c:forEach items="${configVersions}" var="projectVersion">
            <div>
              <admin:editProjectLink projectId="${projectVersion.key.externalId}" addToUrl="&tab=versionedSettings"><admin:projectName project="${projectVersion.key}"/></admin:editProjectLink>
            </div>
          </c:forEach>
        </div>
      </c:when>
      <c:otherwise>
        in <bs:plural txt="project" val="${fn:length(configVersions)}"/>:
        <c:forEach items="${configVersions}" var="projectVersion">
          <div>
            <admin:editProjectLink projectId="${projectVersion.key.externalId}" addToUrl="&tab=versionedSettings"><admin:projectName project="${projectVersion.key}"/></admin:editProjectLink>
          </div>
        </c:forEach>
      </c:otherwise>
    </c:choose>
  </c:when>

  <c:when test="${not empty convertedSettings}">
    DSL scripts should be updated to produce settings for version <c:out value="${currentConfigsVersion}"/><bs:helpLink file="Upgrading+DSL"><bs:helpIcon/></bs:helpLink>:

    <c:if test="${showMode == inplaceMode}"><a href="javascript:;" onclick="$j('#${detailsBlockId}').toggle();">Show details &raquo;</a></c:if>
    <div id="${detailsBlockId}" style="display: ${showMode == inplaceMode ? 'none' : ''}">
      <c:forEach items="${convertedSettings}" var="converted">
        <div class="converterBlock">
          <c:if test="${not empty converted.projects}">
            <div class="affectedEntities">
              <div><strong>change DSL for <bs:plural txt="project" val="${fn:length(converted.projects)}"/>:</strong></div>
              <c:forEach items="${converted.projects}" var="proj">
                <div class="convertedEntity"><admin:editProjectLink projectId="${proj.externalId}"><admin:projectName project="${proj}"/></admin:editProjectLink></div>
              </c:forEach>
            </div>
          </c:if>

          <c:if test="${not empty converted.buildTypes}">
            <div class="affectedEntities">
              <div><strong>change DSL for <bs:plural txt="build configuration" val="${fn:length(converted.buildTypes)}"/>:</strong></div>
              <c:forEach items="${converted.buildTypes}" var="bt">
                <div class="convertedEntity"><admin:editBuildTypeLink buildTypeId="${bt.externalId}"><c:out value="${bt.name}"/></admin:editBuildTypeLink></div>
              </c:forEach>
            </div>
          </c:if>

          <c:if test="${not empty converted.templates}">
            <div class="affectedEntities">
              <div><strong>change DSL for <bs:plural txt="template" val="${fn:length(converted.templates)}"/>:</strong></div>
              <c:forEach items="${converted.templates}" var="template">
                <div class="convertedEntity"><admin:editTemplateLink templateId="${template.externalId}"><c:out value="${template.name}"/></admin:editTemplateLink></div>
              </c:forEach>
            </div>
          </c:if>

          <c:if test="${not empty converted.vcsRoots}">
            <c:set var="cameFromUrl" value="${showMode eq inplaceMode ? pageUrl : healthStatusReportUrl}"/>
            <div class="affectedEntities">
              <div><strong>change DSL for <bs:plural txt="VCS root" val="${fn:length(converted.vcsRoots)}"/>:</strong></div>
              <c:forEach items="${converted.vcsRoots}" var="vcsRoot">
                <div class="convertedEntity"><admin:editVcsRootLink vcsRoot="${vcsRoot}" editingScope="none" cameFromUrl="${pageUrl}"><c:out value="${vcsRoot.name}"/></admin:editVcsRootLink></div>
              </c:forEach>
            </div>
          </c:if>
          <div class="converterSubj">
            <strong>to update DSL, do the following:</strong><br/>
            <bs:out value="${converted.converterSubject}"/>
          </div>
        </div>
      </c:forEach>
    </div>

  </c:when>
</c:choose>

