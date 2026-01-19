<%@ page contentType="text/html;charset=UTF-8" language="java" session="true"
  %><%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"
  %><%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt"
  %><%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions"
  %><%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
  %><%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop"
  %><%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>

<jsp:useBean id="coverageSummaryBean" type="jetbrains.buildServer.coverage.CoverageSummaryBean" scope="request"/>

<bs:_collapsibleBlock title="Code coverage" id="coverageSummary" contentClass="coverageSummary">
  <c:choose>
    <c:when test="${coverageSummaryBean.build.buildPromotion.compositeBuild}">
      <c:set var="projectsHierarchy" value="${coverageSummaryBean.projectsHierarchy}"/>
      <bs:projectHierarchy treeId="coverage_builds_tree" rootProjects="${projectsHierarchy}"
                           rootNotCollapsible="false" persistBlocksState="true"
                           tableClass="modificationBuilds" tableBuildTypeClass="buildTypeProblem"
                           showBuildTypeDescriptions="true" showProjectDescriptions="false"
                           linksToAdminPage="false" showResponsibilityInfo="true" collapsible="true" collapsedByDefault="false" showCounters="false">
        <jsp:attribute name="projectHTML"></jsp:attribute>
        <jsp:attribute name="buildTypeNameHTML">
          <bs:projectOrBuildTypeIcon type="buildType" composite="${buildType.compositeBuildType}"/><bs:buildTypeLinkFull buildType="${buildType}" skipContextProject="true" popupMode="no_self" dontShowProjectName="true"/>
        </jsp:attribute>
        <jsp:attribute name="buildTypeHTML">
          <c:set var="coverageSummary" value="${coverageSummaryBean.coverageSummaryMap[buildType]}"/>
          <td class="coverageStats"><%@include file="coverageStats.jsp"%></td>
        </jsp:attribute>
      </bs:projectHierarchy>
    </c:when>
    <c:otherwise>
      <c:set var="coverageSummary" value="${coverageSummaryBean.coverageSummaryMap[coverageSummaryBean.build.buildType]}"/>
      <div class="coverageStats"><%@include file="coverageStats.jsp"%></div>
    </c:otherwise>
  </c:choose>

</bs:_collapsibleBlock>
