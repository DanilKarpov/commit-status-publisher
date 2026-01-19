<%@ page import="jetbrains.buildServer.buildFailures.BuildFailureOnMetricCondition"
    %>
<%@ page import="jetbrains.buildServer.buildFailures.MetricComparingCondition" %>
<%@ include file="/include.jsp"
    %><%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>

<jsp:useBean id="bean" type="jetbrains.buildServer.buildFailures.BuildFailureOnMetricBean" scope="request" />
<c:set var="metricThresholdKey" value="<%= BuildFailureOnMetricCondition.METRIC_THRESHOLD%>"/>
<c:set var="moreLessKey" value="<%= BuildFailureOnMetricCondition.MORE_OR_LESS%>"/>
<c:set var="metricKey" value="<%= BuildFailureOnMetricCondition.METRIC_KEY%>"/>
<c:set var="withBuildAnchorKey" value="<%= BuildFailureOnMetricCondition.WITH_ANCHOR_KEY%>"/>
<c:set var="anchorBuildKey" value="<%= BuildFailureOnMetricCondition.ANCHOR_BUILD_KEY%>"/>
<c:set var="metricUnitsKey" value="<%= BuildFailureOnMetricCondition.METRIC_UNITS_KEY%>"/>
<c:set var="metricUnitsPercents" value="<%= BuildFailureOnMetricCondition.METRIC_UNITS_PERCENTS%>"/>
<c:set var="metricUnitsDefault" value="<%= BuildFailureOnMetricCondition.METRIC_UNITS_DEFAULT%>"/>
<c:set var="stopBuildOnFailure" value="<%= BuildFailureOnMetricCondition.STOP_BUILD_ON_FAILURE%>"/>
<style>
  #anchorBuild option {
    text-transform: lowercase;
  }

  tr.editBuildFailureOnMetric th {
    vertical-align: top;
  }

  tr.editBuildFailureOnMetric td {
    padding-right: 0;
    vertical-align: top;
  }

  tr.editBuildFailureOnMetric div.topShift {
    margin-top: 0.75em;
  }

  tr.editBuildFailureOnMetric label.anchorLabel {
    display: inline-block;
  }

  tr.editBuildFailureOnMetric label.anchorLabel.anchorRight {
    text-align: right;
    padding: 2px 0;
  }

  #anchorBuildSettings {
    margin-left: 15px;
    margin-top: 5px;
  }

  .noteAboutBytes {
    display: block;
    padding-top: 5px;
  }

</style>


<tr class="editBuildFailureOnMetric">
  <th rowspan="3">Fail build if:<bs:help file="Build+Failure+Conditions" anchor="Failbuildonmetricchange"/></th>
  <td style="width:8em;padding-right:0;">its</td>
  <td>
    <!-- Metric selector:-->
    <props:selectProperty name="${metricKey}" onchange="BS.EditBuildFailure.updateMetricDefaultUnits();">
      <c:forEach items="${bean.buildMetrics}" var="metric">
        <props:option value="${metric.key}"><c:out value="${metric.description}"/></props:option>
      </c:forEach>
    </props:selectProperty>

    <!-- here we store metric default units if available -->
    <c:forEach items="${bean.buildMetrics}" var="metric">
      <c:set var="metricUnits">${bean.getMetricUnits(metric)}</c:set>
      <c:if test="${not empty metricUnits}"><span style="display: none;" id="${metric.key}_default_units">${metricUnits}</span></c:if>
    </c:forEach>
  </td>
</tr>
<tr class="editBuildFailureOnMetric">
  <td style="width:8em;padding-right:0;">compared to</td>
  <td>
    <props:radioButtonProperty name="${withBuildAnchorKey}" id="${withBuildAnchorKey}_false" value="false" checked="${true}" onclick="BS.EditBuildFailure.enableAnchor(!this.checked);"/>
    <label for="${withBuildAnchorKey}_false">constant value</label>
    <br/>
    <props:radioButtonProperty name="${withBuildAnchorKey}" id="${withBuildAnchorKey}_true" value="true" onclick="BS.EditBuildFailure.enableAnchor(this.checked);"/>
    <label for="${withBuildAnchorKey}_true">value from ...</label>

    <div id="anchorBuildSettings">
      <props:selectProperty name="${anchorBuildKey}" onchange="BS.EditBuildFailure.updateFieldVisibility();">
        <forms:buildAnchorOptions selected=""/>
      </props:selectProperty>
      <div id="buildNumberField" class="buildNumberPattern topShift" style="display:none">
        <label for="buildNumberPattern" class="anchorLabel anchorRight">#</label>
        <props:textProperty name="buildNumberPattern" size="12" maxlength="100"
                            style="width: 17em"/><bs:help file="ConfiguringGeneralSettings-BuildNumberFormat"/>
        <span class="error" id="error_buildNumberPattern"></span>
      </div>

      <div id="buildTagField" class="buildNumberPattern topShift" style="display:none">
        <label for="buildTag" class="anchorLabel anchorRight">tag:</label>
        <props:textProperty name="buildTag" size="12" maxlength="60"
                            style="width: 17em"/><bs:help file="Build+Tag"/>
        <span class="error" id="error_buildTag"></span>
      </div>
    </div>



  </td>
</tr>
<tr class="editBuildFailureOnMetric">
  <td style="width:8em;padding-right:0;">is</td>
  <td>
    <props:selectProperty name="${moreLessKey}" style="min-width: 4em;" onchange="BS.EditBuildFailure.updateStopBuildRowVisibility();">
      <c:forEach items="<%=MetricComparingCondition.values()%>" var="v">
        <props:option value="${v}"> ${v.stringRepresentation} </props:option>
      </c:forEach>
    </props:selectProperty>
    &nbsp;
    <span id="anchorBuildComparisonText">than</span>
    &nbsp;
    <props:textProperty name="${metricThresholdKey}" style="width: 70px;" expandable="${false}" className="disableBuildTypeParams"/>
    &nbsp;
    <props:selectProperty name="${metricUnitsKey}" onchange="BS.EditBuildFailure.enableOrDisableBuildAnchor();" style="max-width: 11em;">
      <props:option value="${metricUnitsDefault}">default metric units</props:option>
      <props:option value="${metricUnitsPercents}">percent (compared to a previous build)</props:option>
    </props:selectProperty>
    <span class="error" id="error_${metricThresholdKey}"></span>
    <span class="grayNote noteAboutBytes">You can use format like 30MB (KB, GB, TB) for the field value</span>
  </td>
</tr>
<tr id="stopBuildRow" class="editBuildFailureOnMetric">
  <th>
    <label for="${stopBuildOnFailure}">Stop build:</label>
  </th>
  <td colspan="2">
    <label for="${stopBuildOnFailure}">
    <props:checkboxProperty name="${stopBuildOnFailure}"/>
    Immediately stop the build if it fails due to the condition
    </label>
  </td>
</tr>

<script>
  // TODO move to external JS
  BS.EditBuildFailure = {
    enableAnchor: function(enable) {
      var settings = $j('#anchorBuildSettings');
      enable ? settings.show() : settings.hide();

      $j('#anchorBuildComparisonText').html(enable ? 'by at least' : 'than');
    },

    updateFieldVisibility: function() {
      var buildNumberSelected = $('${anchorBuildKey}').selectedIndex == 3;
      var buildTagSelected = $('${anchorBuildKey}').selectedIndex == 4;

      $('buildNumberField').hide();
      $('buildTagField').hide();
      if (buildNumberSelected) {
        $('buildNumberField').show();
      }
      if (buildTagSelected) {
        $('buildTagField').show();
      }

      BS.VisibilityHandlers.updateVisibility('featureParams');
    },

    updateStopBuildRowVisibility: function() {
      var isMoreSelected = $('${moreLessKey}')[$('${moreLessKey}').selectedIndex].text == '<%=MetricComparingCondition.more.getStringRepresentation()%>';
      if (isMoreSelected) {
        $('stopBuildRow').show();
      } else {
        $('stopBuildRow').hide();
      }
      BS.VisibilityHandlers.updateVisibility('stopBuildRow');
    },

    check: function(/*jquery*/elem, checked) {
      elem.prop('checked', checked);
    },

    disable: function(/*jquery*/elem, disabled) {
      elem.prop('disabled', disabled);
    },

    enableOrDisableBuildAnchor: function() {
      var requiresAnchor = this._percentAreSelected();

      var withBuildAnchor = $j('#${withBuildAnchorKey}_true');
      if (requiresAnchor) {
        BS.EditBuildFailure.check(withBuildAnchor, requiresAnchor);
      }
      BS.EditBuildFailure.disable(withBuildAnchor, requiresAnchor);

      var withoutBuildAnchor = $j('#${withBuildAnchorKey}_false');
      BS.EditBuildFailure.disable(withoutBuildAnchor, requiresAnchor);

      this.enableAnchor(withBuildAnchor.prop('checked'));
      this.updateBytesLine();
    },

    _metricUnits: function() {
      var metricKey = $j('#${metricKey} :selected').val();
      return $j('#' + metricKey + '_default_units').text();
    },

    _percentAreSelected: function () {
      return $j('#${metricUnitsKey} :selected').val() == '${metricUnitsPercents}'
    },

    updateMetricDefaultUnits: function() {
      $j('#${metricUnitsKey} option[value="${metricUnitsDefault}"]').text(this._metricUnits() || 'default metric units');
      this.updateBytesLine();
    },

    updateBytesLine: function() {
      var bytesAreUsed = 'bytes' === this._metricUnits();
      var bytesAreSelected = !this._percentAreSelected();
      $j('.noteAboutBytes')[bytesAreUsed && bytesAreSelected ? 'show' : 'hide']();
    }
  };

  BS.EditBuildFailure.updateMetricDefaultUnits();
  BS.EditBuildFailure.enableOrDisableBuildAnchor();
  BS.EditBuildFailure.updateFieldVisibility();
  BS.EditBuildFailure.updateStopBuildRowVisibility();
  BS.jQueryDropdown('#${metricKey},#${anchorBuildKey}').ufd("changeOptions");

</script>
