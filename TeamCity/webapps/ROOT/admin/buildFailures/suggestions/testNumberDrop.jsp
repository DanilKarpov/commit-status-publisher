<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.SBuildType" scope="request"/>
<div class="suggestionItem">
  Builds of <admin:editBuildTypeLinkFull buildType="${buildType}"/> report tests.
  You can fail a build if <strong>number of tests</strong> significantly decreases.<bs:help file="Build+Failure+Conditions"/>
  <div>
    <c:set var="failureConditionsUrl"><admin:editBuildTypeLink buildTypeId="${buildType.externalId}" withoutLink="true" step="buildFailureConditions"/></c:set>
    <forms:addLink href="${failureConditionsUrl}&metricKey=buildTestCount&metricThreshold=20&moreOrLess=less&withBuildAnchor=true&anchorBuild=lastSuccessful&metricUnits=metricUnitsPercents#addFeature=BuildFailureOnMetric">Add Failure Condition</forms:addLink>
  </div>
</div>

