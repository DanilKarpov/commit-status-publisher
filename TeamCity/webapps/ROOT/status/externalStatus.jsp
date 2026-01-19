<%@ include file="../include-internal.jsp" %>
<%--@elvariable id="contextProject" type="jetbrains.buildServer.serverSide.SProject"--%>

<c:if test="${not empty param['withCss']}">
  <bs:linkCSS>
    /css/icons.css
    /css/status/externalStatus.css
  </bs:linkCSS>
</c:if>

<c:forEach items="${projectMap}" var="project">

  <table class="tcTable">
    <tr>
      <td colspan="3" class="tcTD_projectName">
        <div class="projectName">
          <bs:projectLinkFull project="${project.key}" contextProject="${contextProject}"/>
        </div>
      </td>
    </tr>

    <c:forEach items="${project.value}" var="buildType">
      <jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.SBuildType"/>

      <tr>
        <td class="buildConfigurationName">
          <bs:buildTypeIcon buildType="${buildType}" ignorePause="true" simpleTitle="true"/>
          <bs:buildTypeLink buildType="${buildType}"/>
        </td>

        <c:set var="buildData" value="${lastChangesFinishedMap[buildType]}"/>
        <td class="buildNumberDate">
          <c:if test="${not empty buildData}">
            <div class="teamCityBuildNumber">build <bs:buildNumber buildData="${buildData}" withLink="true"/></div>
            <div class="teamCityDateTime"><bs:date value="${buildData.finishDate}"/></div>
          </c:if>
        </td>
        <td class="buildResults">
          <c:if test="${not empty buildData}">
            <div class="teamCityBuildResults">
              <c:if test="${buildData.artifactsExists or buildData.hasInternalArtifactsOnly}">
                <span class="teamCityIcon">
                  <bs:_artifactsLink text="true" build="${buildData}" noPopup="true">artifacts</bs:_artifactsLink>
                </span>
              </c:if>
              <c:if test="${not buildData.artifactsExists}">
                <span class="teamCityIcon">
                  <bs:buildDataIcon buildData="${buildData}" simpleTitle="true"/>
                  <bs:resultsLink build="${buildData}" noPopup="true">results</bs:resultsLink>
                </span>
              </c:if>
            </div>
          </c:if>
        </td>
      </tr>

    </c:forEach>
  </table>

</c:forEach>
