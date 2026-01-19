<%@ page import="jetbrains.buildServer.buildFailures.buildLog.MessagePatternCondition" %>

<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms" %>

<jsp:useBean id="propertiesBean" scope="request" type="jetbrains.buildServer.controllers.BasePropertiesBean"/>
<jsp:useBean id="supportedConditions" scope="request" type="java.util.List"/>
<jsp:useBean id="canTestOnFinishedBuild" scope="request" type="java.lang.Boolean"/>

<c:set var="conditionTypeKey" value="<%= MessagePatternCondition.CONDITION_TYPE%>"/>
<c:set var="messagePatternKey" value="<%= MessagePatternCondition.MESSAGE_PATTERN%>"/>
<c:set var="outputTextKey" value="<%= MessagePatternCondition.OUTPUT_TEXT%>"/>
<c:set var="reverseKey" value="<%= MessagePatternCondition.REVERSE%>"/>
<c:set var="stopBuildOnFailure" value="<%= MessagePatternCondition.STOP_BUILD_ON_FAILURE%>"/>
<c:set var="reportOnlyFirstMatch" value="<%= MessagePatternCondition.REPORT_ONLY_FIRST_MATCH%>"/>
<c:set var="finishedBuildIdKey" value="buildFailureOnMessage.finishedBuildId"/>

<c:set var="selectedConditionType" value="${propertiesBean.properties[conditionTypeKey]}"/>
<c:set var="reportOnlyFirstMatchVal" value="${propertiesBean.properties[reportOnlyFirstMatch]}"/>

<tr class="noBorder">
  <th>
    <label for="${reverseKey}">Fail build if its build log:<bs:help file="Build+Failure+Conditions" anchor="Failbuildonspecifictextinbuildlog"/></label>
  </th>
  <td>
    <div style="padding-bottom:8px;">
      <c:set var="onchange">
        <c:forEach var="conditionType" items="${supportedConditions}">
          $('${conditionType.name}' + '_descr').hide();
        </c:forEach>
        var selectedValue = this.options[this.selectedIndex].value;
        $(selectedValue + '_descr').show();
      </c:set>
      <props:selectProperty name="${reverseKey}" onchange="BS.EditBuildFailureOnMessage.updateRowVisibility();">
        <props:option value="false">contains</props:option>
        <props:option value="true">doesn't contain</props:option>
      </props:selectProperty>
      &nbsp;&nbsp;&nbsp;
      <props:selectProperty name="${conditionTypeKey}" onchange="${onchange}">
        <c:forEach var="conditionType" items="${supportedConditions}">
          <props:option value="${conditionType.name}"><c:out value="${conditionType.displayName}"/></props:option>
        </c:forEach>
      </props:selectProperty>
    </div>

    <div>
      <props:textProperty name="${messagePatternKey}" className="textProperty_max-width js_max-width"/>
      <span id="error_${messagePatternKey}" class="error"></span>

      <c:forEach var="conditionType" items="${supportedConditions}">
        <span id="${conditionType.name}_descr" class="smallNote"
              style="${conditionType.name eq selectedConditionType and not empty conditionType.patternDescription ? "" : "display:none;"}">${conditionType.patternDescription}</span>
      </c:forEach>
      <c:if test="${empty selectedConditionType}">
        <script>
          (function() {
            var selectedValue = $('${conditionTypeKey}').options[0].value;
            $(selectedValue + '_descr').show();
          })();
        </script>
      </c:if>
    </div>
  </td>
</tr>
<tr class="noBorder">
  <th>
    <label for="${outputTextKey}">Failure message:</label>
  </th>
  <td>
    <props:textProperty name="${outputTextKey}" className="textProperty_max-width js_max-width"/>
    <span class="smallNote">The message to display in the UI and the build log.</span>
  </td>
</tr>
<tr id="stopBuildOnFailureRow" class="noBorder">
  <th>
    <label for="${stopBuildOnFailure}">Stop build:</label>
  </th>
  <td>
    <label for="${stopBuildOnFailure}">
    <props:checkboxProperty name="${stopBuildOnFailure}" onclick="BS.EditBuildFailureOnMessage.updateRowVisibility();"/>
    Immediately stop the build if it fails due to the condition.
    </label>
  </td>
</tr>
<tr id="reportOnlyFirstMatchRow" class="noBorder">
  <th>
    <label for="${reportOnlyFirstMatch}">Build problem reporting:</label>
  </th>
  <td>
    <label for="${reportOnlyFirstMatch}">
    <props:checkboxProperty name="${reportOnlyFirstMatch}" value="" uncheckedValue="false" checked="${empty reportOnlyFirstMatchVal or 'true' eq reportOnlyFirstMatchVal}"/>
      Create build problem only on the first match
    </label>
  </td>
</tr>

<c:if test="${canTestOnFinishedBuild}">
  <tr>
    <td colspan="2">
      <input id="testOnFinishedBuildButton" type="button" value="Test on finished build"
             onclick="BS.TestOnFinishedBuildDialog.showCentered();" class="btn submitButton" style="margin:0"/>
    </td>
  </tr>
  <tr class="hidden">
    <td colspan="2">
      <jsp:useBean id="buildHistory" scope="request" type="java.util.List"/>

      <bs:dialog dialogId="testOnFinishedBuildDialog"
                 title="Test build failure on message on a finished build"
                 closeCommand="BS.TestOnFinishedBuildDialog.close();">
        <table class="runnerFormTable">
          <tr class="noBorder">
            <th>
              <label for="${finishedBuildIdKey}">Select build:</label>
            </th>
            <td>
              <forms:select name="${finishedBuildIdKey}" style="width:100%;">
                <c:forEach var="build" items="${buildHistory}">
                  <forms:option value="${build.buildId}"><bs:buildNumber buildData="${build}" withLink="false"/> <c:out
                      value="${build.statusDescriptor.text}"/></forms:option>
                </c:forEach>
              </forms:select>
            </td>
          </tr>
          <tr class="noBorder">
            <td id="testOnFinishedBuildResult" colspan="2" style="border-top:none;"></td>
          </tr>
        </table>
        <div class="popupSaveButtonsBlock">
          <input type="button" value="Test" onclick="BS.TestOnFinishedBuildDialog.submit();" class="btn btn_primary submitButton"/>
          <forms:cancel onclick="BS.TestOnFinishedBuildDialog.close();"/>
          <forms:saving id="testOnFinishedBuildProgress"/>
        </div>
      </bs:dialog>
    </td>
  </tr>
</c:if>
<script>
  BS.EditBuildFailureOnMessage = {
    updateRowVisibility: function() {
      var selectedValue = $('${reverseKey}').options[$('${reverseKey}').selectedIndex].value;
      if ('true' == selectedValue) {
        $('stopBuildOnFailureRow').hide();
        $('reportOnlyFirstMatchRow').hide();
      } else {
        $('stopBuildOnFailureRow').show();
        if ($('${stopBuildOnFailure}').checked) {
          $('reportOnlyFirstMatchRow').hide();
        } else {
          $('reportOnlyFirstMatchRow').show();
        }
      }
      BS.VisibilityHandlers.updateVisibility('stopBuildOnFailureRow');
      BS.VisibilityHandlers.updateVisibility('reportOnlyFirstMatchRow');
    }
  };
  BS.EditBuildFailureOnMessage.updateRowVisibility();
</script>
