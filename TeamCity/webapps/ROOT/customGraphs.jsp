<%@ page import="java.util.HashSet"
%><%@ page import="java.util.Set"
%>
<%@ page import="jetbrains.buildServer.serverSide.auth.Permission" %>
<%@ page import="jetbrains.buildServer.web.statistics.graph.RenderableChart" %>
<%@ page import="jetbrains.buildServer.web.util.SessionUser" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="customGraphs" scope="request" type="java.util.List<jetbrains.buildServer.web.statistics.graph.RenderableChart>"/>
<%--@elvariable id="chartGroup" type="java.lang.String"--%>
<%--@elvariable id="project" type="jetbrains.buildServer.serverSide.SProject"--%>
<%--@elvariable id="buildType" type="jetbrains.buildServer.serverSide.SBuildType"--%>
<c:set value="${not empty buildType ? buildType.project.projectId : project.projectId}" var="currentProjectId"/>
<c:if test="${empty project}">
  <c:set var="project" value="${buildType.project}"/>
</c:if>

<bs:linkScript>
  /js/bs/editCustomCharts.js
</bs:linkScript>

<%
  final Set<RenderableChart> visibleCharts = new HashSet<RenderableChart>();

  final jetbrains.buildServer.web.statistics.graph.BuildGraphHelper helper = (jetbrains.buildServer.web.statistics.graph.BuildGraphHelper)request.getAttribute("buildGraphHelper");
  if (helper != null) {
    for (final RenderableChart customGraph : customGraphs) {
      if (customGraph.getValueType().hasData(helper.createSettings(request, pageContext, customGraph.getAdditionalProperties()))) {
        visibleCharts.add(customGraph);
      }
    }
  }

  pageContext.setAttribute("visibleCharts", visibleCharts);
%>

<c:set var="permissionGrantedForAnyProject"><%=SessionUser.getUser(request).isPermissionGrantedForAnyProject(Permission.EDIT_PROJECT)%></c:set>
<c:set var="authorizedInCurrent"><authz:authorize projectId="${currentProjectId}" allPermissions="EDIT_PROJECT">true</authz:authorize></c:set>
<c:forEach items="${customGraphs}" var="chart">
  <c:set var="authorized"><authz:authorize projectId="${chart.ownerProject.projectId}" allPermissions="EDIT_PROJECT">true</authz:authorize></c:set>
  <c:set var="readOnly" value="${chart.ownerProject.readOnly}"/>
  <div id="${chart.valueType.key}CustomChart" class="customChart<c:if test="${authorized and not readOnly}"> editable</c:if>">
    <graph:buildGraph id="${chart.ownerProject.externalId}${chart.key}" valueType="${chart.valueType.key}" hideFilters="${chart.hideFilters}" projectExternalId="${chart.ownerProject.externalId}" valueTypeBean="${chart.valueType}"
                      defaultFilter="${chart.defaultFilter}" defaults="${chart.additionalProperties}" buildTypeExternalId="${empty chart.sourceBuildType ? buildType.externalId : chart.sourceBuildType.externalId}" hints="${chart.hints}" isPredefined="${chart.hints}"
                      additionalProperties="chartGroup">
      <jsp:attribute name="additionalActions">
        <c:choose>
          <c:when test="${!chart.modifiable}">
              <bs:actionIcon className="cannotEditIcon" name="info" />
              <script type="text/javascript">
                $j(function() {
                  $j(".cannotEditIcon").on("click mouseover", function(e) {
                    BS.Tooltip.showMessage(e.currentTarget, {}, "This is a predefined chart and cannot be edited");
                    return false;
                  }).on("mouseout", function() {BS.Tooltip.hidePopup();});
                });
              </script>
          </c:when>
          <c:when test="${readOnly}">
              <bs:actionIcon className="cannotEditIcon" name="info" />
              <script type="text/javascript">
                $j(function() {
                  $j(".cannotEditIcon").on("click mouseover", function(e) {
                    BS.Tooltip.showMessage(e.currentTarget, {}, "This chart is defined in the read-only project '<c:out value="${chart.ownerProject.fullName}"/>' and cannot be edited");
                    return false;
                  }).on("mouseout", function() {BS.Tooltip.hidePopup();});
                });
              </script>
          </c:when>
          <c:when test="${authorized}">
            <bs:actionIcon
                name="pencil"
                title="Edit chart"
                className="editChartToggle"
                attrs="data-chart-id='${chart.valueType.key}' data-chart-group='${chartGroup}' data-buildtype-id='${buildType.externalId}' data-project-id='${chart.ownerProject.externalId}'"
            />
          </c:when>
          <c:when test="${chart.ownerProject != project and permissionGrantedForAnyProject}">
              <bs:actionIcon className="cannotEditIcon" name="info" />
              <script type="text/javascript">
                $j(function() {
                  $j(".cannotEditIcon").on("click mouseover", function(e) {
                    BS.Tooltip.showMessage(e.currentTarget, {}, "This chart is defined in the project you cannot edit: <c:out value="${chart.ownerProject.fullName}"/>");
                    return false;
                  }).on("mouseout", function() {BS.Tooltip.hidePopup();});
                });
              </script>
          </c:when>
        </c:choose>
      </jsp:attribute>
    </graph:buildGraph>
  </div>
</c:forEach>

<script type="text/javascript">
  $j(function() {
    $j(document).on("click", ".graphSettingsPopup .saveButtonsBlock .saveDefaults", function (e) {
      var $button = $j(e.currentTarget);
      var parents = $button.parents("form");
      if (parents.length > 0) {
        $j(parents[0]).append("<input type='hidden' name='_setYAxisDefaults' value='true'>");
        $button.siblings(".submitButton").click();
      }
      return false;
    });
  });
</script>

<c:if test="${not project.readOnly}">
<authz:authorize projectId="${currentProjectId}" allPermissions="EDIT_PROJECT">
  <bs:editChartDialog keysDescriptions="${keysDescriptions}" currentProjectId="${currentProjectId}">
    <jsp:attribute name="additionalContent">
      <c:if test="${empty buildType and not empty managedProjects}">
        <div class="buildTypeChooser group">
          <label for="buildTypeChooser" class="title">Source Build Configuration:</label>
          <select hidden name="buildTypeChooser"  id="buildTypeChooser">
            <c:forEach items="${managedProjects}" var="project" varStatus="status">
              <c:forEach var="buildType" items="${project.ownBuildTypes}">
                <option value="${buildType.externalId}"></option>
              </c:forEach>
            </c:forEach>
          </select>
          <div id="buildTypeChooserSelect" ></div>
          <span style="display: none" class="spinner"><i class="icon-refresh icon-spin ring-loader-inline"></i></span>
          <bs:buildTypeLink classes="btLink" style="display: none" buildType="${buildType}" additionalUrlParams="&tab=buildTypeStatistics">see statistics tab</bs:buildTypeLink>
        </div>
      </c:if>
    </jsp:attribute>
  </bs:editChartDialog>
  <div class="addChartButtonHolder" style="display: none">
    <a class="btn editChartToggle" onclick="return false;" data-buildtype-id="${buildType.externalId}" data-project-id="${currentProjectId}" data-chart-group="${chartGroup}"><span class="icon_before icon16 addNew">Add new chart</span></a>
    <c:if test="${(not empty buildType or not empty managedProjects) and fn:length(visibleCharts) > 1}">
      <a class="btn reorderChartsButton" onclick="return false;" data-buildtype-id="${buildType.externalId}" data-project-id="${currentProjectId}" data-chart-group="${chartGroup}"><span class="reorder">Reorder</span></a>
      <c:url var="action" value="/admin/blabla.html"/>
      <bs:reorderDialog dialogId="reorderChartsDialog" dialogTitle="Charts">
        <jsp:attribute name="sortables">
          <c:forEach items="${customGraphs}" var="chart">
            <div data-is-visible="${util:contains(visibleCharts, chart)}" class="chart ${not util:contains(visibleCharts, chart) ? ' hidden' : ' draggable'}" id="ord_${chart.ownerProject.externalId}:${chart.valueType.key}"><c:out value="${chart.title}"/> <c:if test="${chart.ownerProject != project && chart.ownerProject != buildType.project && !chart.modifiable}">(from <bs:projectLink project="${chart.ownerProject}"/>)</c:if><c:if test="${chart.modifiable}">(default chart)</c:if></div>
          </c:forEach>
        </jsp:attribute>
      </bs:reorderDialog>
    </c:if>
  </div>
  <script type="text/javascript">
    $j(function () {
      var $targetContainer = $j(".GraphContainer:first");
      var $holder = $j(".addChartButtonHolder");
      if ($targetContainer.length > 0) {
        $targetContainer.before($holder);
      } else {
        $j("#mainContent").append($holder);
      }
      $holder.show();

      if (BS.CustomChart) {
        var popup = BS.CustomChart.initEditListeners('${currentProjectId}', '${chartGroup}');

        if (popup.getPopupElement().find("#buildTypeChooser").length > 0) {
          BS.CustomChart.initBuildTypeChooser(popup);
        } else {
          var initialized = false;
          $j(document).on("click", ".editChartToggle", function (e) {
            if (!initialized) {
              initialized = true;
              BS.CustomChart.updateValueTypes(popup, '${buildType.externalId}', false);
            }
          });
        }
      }
    });
  </script>
</authz:authorize>
</c:if>