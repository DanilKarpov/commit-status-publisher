<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="buildType" value="${healthStatusItem.additionalData.get('buildType')}"/>

Build configuration <admin:editBuildTypeLinkFull step="${healthStatusItem.additionalData.getOrDefault('btStepId', 'general')}" buildType="${healthStatusItem.additionalData.get('buildType')}"/>:
<br>

<c:if test="${healthStatusItem.additionalData.get('type').equals('vcs')}">
  <c:url var="vcsSettingsUrl" value="/admin/editBuildTypeVcsRoots.html?init=1&id=buildType:${buildType.externalId}"/>
  Branch filter in the
  <a href="${vcsSettingsUrl}">
    Version Control Settings
  </a>
</c:if>

<c:if test="${healthStatusItem.additionalData.get('type').equals('trigger')}">
  <c:url var="triggerUrl" value="/admin/editTriggers.html?init=1&id=buildType:${buildType.externalId}#editTrigger=${healthStatusItem.additionalData.get('objectId')}"/>
  Branch filter of the
  <a href="${triggerUrl}">
      ${healthStatusItem.additionalData.get('name')} Trigger
  </a>
</c:if>

<c:if test="${healthStatusItem.additionalData.get('type').equals('scheduleTriggerDep')}">
  <c:url var="triggerUrl" value="/admin/editTriggers.html?init=1&id=buildType:${buildType.externalId}#editTrigger=${healthStatusItem.additionalData.get('objectId')}"/>
  Watched build branch filter of the
  <a href="${triggerUrl}">
      ${healthStatusItem.additionalData.get('name')} Trigger
  </a>
</c:if>

<c:if test="${healthStatusItem.additionalData.get('type').equals('feature')}">
  <c:url var="featureUrl" value="/admin/editBuildFeatures.html?init=1&id=buildType:${buildType.externalId}#editFeature=${healthStatusItem.additionalData.get('objectId')}"/>
  Branch filter of the
  <a href="${featureUrl}">
      ${healthStatusItem.additionalData.get('name')} build feature
  </a>
</c:if>

<c:if test="${healthStatusItem.additionalData.get('type').equals('artifact_dep')}">
  <c:url var="artifactDepUrl" value="/admin/editDependencies.html?init=1&id=buildType:${buildType.externalId}"/>
  Branch filter of the
  <a href="${artifactDepUrl}">
    artifact dependency
  </a>
</c:if>

<bs:out>${healthStatusItem.additionalData.get("descriptionBeforeDep")}</bs:out>

<c:if test="${healthStatusItem.additionalData.containsKey('depBuildType')}">
  <admin:editBuildTypeLinkFull step="buildFeatures" buildType="${healthStatusItem.additionalData.get('depBuildType')}"/>
  <bs:out>${healthStatusItem.additionalData.get("descriptionAfterDep")}</bs:out>
</c:if>