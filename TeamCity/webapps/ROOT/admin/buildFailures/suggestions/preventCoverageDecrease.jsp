<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.SBuildType" scope="request"/>
<div class="suggestionItem">
  Builds of <admin:editBuildTypeLinkFull buildType="${buildType}"/> report coverage results.
  You can fail a build if <strong>number of covered lines</strong> decreases.<bs:help file="Build+Failure+Conditions"/>

  <div class="suggestionAction">
    <c:set var="failureConditionsUrl"><admin:editBuildTypeLink buildTypeId="${buildType.externalId}" withoutLink="true" step="buildFailureConditions"/></c:set>
    <forms:addLink href="${failureConditionsUrl}&metricKey=CodeCoverageAbsLCovered&metricThreshold=1&moreOrLess=less&withBuildAnchor=true&anchorBuild=lastFinished&metricUnits=metricUnitsPercents#addFeature=BuildFailureOnMetric">Add Failure Condition</forms:addLink>
  </div>
</div>

