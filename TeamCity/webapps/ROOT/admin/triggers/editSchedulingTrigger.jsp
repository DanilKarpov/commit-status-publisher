<%@ page import="java.util.TimeZone" %>
<%@ page import="jetbrains.buildServer.buildTriggers.scheduler.CronField" %>
<%@ page import="jetbrains.buildServer.serverSide.TeamCityProperties" %>
<%@ page import="jetbrains.buildServer.serverSide.vcs.spec.AttributesBranchFiltersProperties" %>
<%@ include file="/include.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<jsp:useBean id="buildForm" type="jetbrains.buildServer.controllers.admin.projects.EditableBuildTypeSettingsForm" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.controllers.BasePropertiesBean" scope="request"/>
<c:set var="isAttributesEnabled" value="<%= AttributesBranchFiltersProperties.isEnabledTriggers() %>"/>

<style type="text/css">
  .clickable-text {
    color:  var(--ring-link-color);
    cursor: pointer;
  }
</style>

<tr>
  <td colspan="2" style="border-top:none">
    <script type="text/javascript">
      BS.ScheduleTriggerSettings = {};

      BS.ScheduleTriggerSettings.selectSchedulerOptions = function () {
        $('branchFilter').focus();
      }
      BS.ScheduleTriggerSettings.onPolicyChange = function () {
        var idx = $('schedulingPolicy').selectedIndex;
        $('weeklyPolicy').style.display = idx === 1 ? '' : 'none';
        $('cronPolicy').style.display = idx === 2 ? '' : 'none';
        $('dailyPolicy').style.display = idx === 0 || idx === 1 ? '' : 'none';
        if (idx === 2) {
          $('cronHelp').show();
        } else {
          $('cronHelp').hide();
        }
        BS.MultilineProperties.updateVisible();
      }
    </script>
    <div>
      <table class="runnerFormTable date-and-time-conditions">
        <tr>
          <td colspan="2"><em>Trigger build if all of the following conditions are met.</em></td>
        </tr>
        <tr class="groupingTitle">
          <td colspan="2">Date and Time</td>
        </tr>
        <tr>
          <td class="_label"><label for="schedulingPolicy">When:</label></td>
          <td>
            <props:selectProperty name="schedulingPolicy" onchange="BS.ScheduleTriggerSettings.onPolicyChange();">
              <props:option value="daily">daily</props:option>
              <props:option value="weekly">weekly</props:option>
              <props:option value="cron">advanced (cron expression)</props:option>
            </props:selectProperty><bs:help id="cronHelp" file="Configuring+Schedule+Triggers"
                                            style="${propertiesBean.properties['schedulingPolicy'] == 'cron' ? '' : 'display: none;'}"/>
          </td>
        </tr>
        <tr id="weeklyPolicy" style="${propertiesBean.properties['schedulingPolicy'] == 'weekly' ? '' : 'display: none;'}">
          <td class="_label">
            <label for="dayOfWeek">Day of the week:</label>
          </td>
          <td>
            <props:selectProperty name="dayOfWeek">
              <props:option value="Sunday">Sunday</props:option>
              <props:option value="Monday">Monday</props:option>
              <props:option value="Tuesday">Tuesday</props:option>
              <props:option value="Wednesday">Wednesday</props:option>
              <props:option value="Thursday">Thursday</props:option>
              <props:option value="Friday">Friday</props:option>
              <props:option value="Saturday">Saturday</props:option>
            </props:selectProperty>
          </td>
        </tr>
        <tr id="dailyPolicy" style="${propertiesBean.properties['schedulingPolicy'] == 'cron' ? 'display: none;' : ''}">
          <td class="_label">
            <label for="hour">Time (HH:mm):</label>
          </td>
          <td>
            <props:selectProperty name="hour">
              <c:forEach begin="0" end="23" step="1" varStatus="pos">
                <props:option value="${pos.index}"><c:if test="${pos.index < 10}">0</c:if>${pos.index}</props:option>
              </c:forEach>
            </props:selectProperty>
            <props:selectProperty name="minute">
              <c:forEach begin="0" end="59" step="5" varStatus="pos">
                <props:option value="${pos.index}"><c:if test="${pos.index < 10}">0</c:if>${pos.index}</props:option>
              </c:forEach>
            </props:selectProperty>
          </td>
        </tr>
        <tr id="cronPolicy" style="${propertiesBean.properties['schedulingPolicy'] == 'cron' ? '' : 'display: none;'}">
          <td/>
          <td class="cron-policy-wrapper">
            <table class="cron-fields-table">
              <tr>
                <c:set var="cronFields" value="<%=CronField.values()%>"/>
                <c:forEach items="${cronFields}" var="field">
                  <c:set var="fieldElement" value="cronExpression_${field.key}"/>
                  <td class="cron-field _top">
                    <props:textProperty name="${fieldElement}" maxlength="100" className="disableBuildTypeParams"/>
                    <span class="error" id="error_${fieldElement}"></span>
                    <bs:smallNote><c:out value="${field.caption}"/><br/><c:out value="${field.descr}"/></bs:smallNote>
                  </td>
                </c:forEach>
              </tr>
            </table>
            <span class="error" id="error_cronExpressionError"></span>
          </td>
        </tr>
        <tr class="noBorder advancedSetting" id="timezoneProps">
          <td class="_label">
            <label for="timezone">Timezone:</label>
          </td>
          <td class="noBorder">
            <c:set var="serverTimeZone" value="<%=TimeZone.getDefault()%>"/>
            <props:selectProperty name="timezone" enableFilter="true">
              <props:option value="SERVER">Server Time Zone - ${util:formatTimeZone(serverTimeZone)}</props:option>
              <c:forEach items="${util:timeZones()}" var="zone">
                <props:option value="${zone.ID}">${util:formatTimeZone(zone)}</props:option>
              </c:forEach>
            </props:selectProperty>
          </td>
        </tr>
        <tr class="groupingTitle">
          <td colspan="2">VCS Changes</td>
        </tr>
        <tr>
          <td colspan="2">
            <props:checkboxProperty name="triggerBuildWithPendingChangesOnly" onclick="BS.ScheduleTriggerInspect.doRefresh();"/> <%-- this here onchange--%>
            <label for="triggerBuildWithPendingChangesOnly">Trigger only if there are pending changes</label>
          </td>
        </tr>
        <tr class="advancedSetting">
          <td class="_top _label">
            <%--@declare id="triggerrules"--%>
            <label for="triggerRules" class="rightLabel">Trigger rules:</label><bs:help file="Configuring+Schedule+Triggers" anchor="buildTriggerRules"/>
          </td>
          <td class="_top">
            <admin:triggerRulesForm buildForm="${buildForm}"/>
          </td>
        </tr>

        <c:set var="branchFilter" value="${propertiesBean.properties['branchFilter']}"/>
        <c:set var="defaultBranchFilter" value='+:*'/>
        <c:if test="${buildForm.template or buildForm.branchesConfigured or (not empty branchFilter and branchFilter != defaultBranchFilter)}">
          <tr class="groupingTitle">
            <td colspan="2">Trigger Build in Branches</td>
          </tr>
          <tr>
            <td style="vertical-align: top;">
              <label for="branchFilter" class="rightLabel">Branch filter:</label><bs:help file="Branch+Filter"/>
            </td>
            <td>
              <c:set var="note">
                <c:choose>
                  <c:when test="${isAttributesEnabled}">
                    New-line delimited list of logical branch names with an optional "*" placeholder (+|-: &lt;name&gt;) or pull request conditions (+|-pr: &lt;properties&gt;)<bs:help file="Branch Filter"/>.<br/>
                  </c:when>
                  <c:otherwise>
                    Newline-delimited set of rules in the form of +|-:logical branch name (with an optional * placeholder).<bs:help file="Branch+Filter"/><br/>
                  </c:otherwise>
                </c:choose>
                If branch filter matches several branches, then build is triggered in matched branches where pending changes and build changes conditions are met.
                <br>
                Click the <span class="clickable-text" onclick="document.getElementById('handle_helper_branchFilter').click()">Magic wand button</span> to invoke the filter expression editor
              </c:set>
              <props:multilineProperty name="branchFilter" linkTitle="Edit Branch Filter" cols="55" rows="3" note="${note}"/>
              <script type="text/javascript">
                BS.BranchFilterHelperPopup.attachHandler('branchFilter', ["branchPattern", "pullRequest"], [BS.BranchesPopup.createParams('${buildForm.settingsId}'), ""]);
              </script>
            </td>
          </tr>
        </c:if>

        <tr class="groupingTitle advancedSetting">
          <td colspan="2">Watched Build</td>
        </tr>
        <jsp:include page="/admin/triggers/schedulingTriggerBuildDependency.html"/>

        <tr class="groupingTitle advancedSetting">
          <td colspan="2">Additional Options</td>
        </tr>

        <c:if test="${not buildForm.compositeBuild}">
          <tr class="advancedSetting">
            <td colspan="2">
              <props:checkboxProperty name="triggerBuildOnAllCompatibleAgents"/>
              <label for="triggerBuildOnAllCompatibleAgents">Trigger build on all enabled and compatible agents</label>
            </td>
          </tr>
        </c:if>

        <tr class="advancedSetting">
          <td colspan="2">
            <props:checkboxProperty name="enableQueueOptimization"/>
            <label for="enableQueueOptimization">Queued build can be replaced with a more recent queued build</label>
          </td>
        </tr>

      </table>
    </div>
  </td>
</tr>
<tr id="warnRow" style="display: none">
  <td colspan="2">
    <div id="branchWarnDiv" class="attentionComment">
    </div>
  </td>
</tr>

<script type="text/javascript">
  BS.ScheduleTriggerInspect = {
    branchFilterElement: $('branchFilter'),
    pendingOnly: $('triggerBuildWithPendingChangesOnly'),
    warnContainer: $('branchWarnDiv'),
    rowId: "warnRow",
    init: function () {
      if (this.branchFilterElement) {
        this.branchFilterElement.onkeyup = BS.ScheduleTriggerInspect.handle;
        this.branchFilterElement.onchange = BS.ScheduleTriggerInspect.handle;
      }
      this.doRefresh();
    },
    handle: function () {
      if (this.timer) {
        clearTimeout(this.timer);
      }
      if (this.value) {
        this.timer = setTimeout(function () {
          BS.ScheduleTriggerInspect.doRefresh();
        }, 2000);
      }
    },
    doRefresh: function () {
      if (this.pendingOnly.checked) {
        this.warnContainer.innerHTML = '';
        BS.Util.hide(this.rowId);
      } else if (this.branchFilterElement) {
        var that = this;
        BS.Util.show('savingTrigger');
        BS.ajaxRequest(window['base_uri'] + "/scheduleTriggerInspect.html", {
          method: 'post',
          evalScripts: true,
          parameters: {
            id: '${buildForm.settingsId}',
            branchFilter: this.branchFilterElement.value
          },
          onComplete: function (transport) {
            var errors = BS.XMLResponse.processErrors(transport.responseXML, {
              onBranchFilterError: function (elem) {
                $('error_branchFilter').innerHTML = elem.firstChild.nodeValue;
              }
            });
            if (!errors) {
              $('error_branchFilter').innerHTML = '';
            }

            if (transport.responseXML && transport.responseXML.firstChild) {
              var response = transport.responseXML.firstChild;
              var safeElement = response.getElementsByTagName("safe")[0];
              if (safeElement && safeElement.firstChild.data === "false") {
                var count = response.getElementsByTagName("branchesCount")[0]
                if (count) {
                  that.warnContainer.innerHTML = "Current trigger settings can cause builds to be triggered in <strong>" + count.firstChild.data + "</strong> branches. "
                    + "Consider enabling <strong>'Trigger only if there are pending changes'</strong> option "
                    + "or <a href='#' onclick='BS.ScheduleTriggerSettings.selectSchedulerOptions();'>adjusting branch filter</a>";
                  BS.Util.show(that.rowId);
                }
              } else {
                that.warnContainer.innerHTML = '';
                BS.Util.hide(that.rowId);
              }
            }
            BS.Util.hide('savingTrigger');
            return false;
          }
        });
      }
    }
  }
  BS.ScheduleTriggerInspect.init();
</script>

