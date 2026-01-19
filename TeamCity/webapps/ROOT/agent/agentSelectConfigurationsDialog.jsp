<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="bean" type="jetbrains.buildServer.controllers.agent.AgentSelectConfigurationsPopupBean" scope="request"/>
<jsp:useBean id="agentTypeId" type="java.lang.String" scope="request"/>

<c:url var="actionUrl" value="/agent/agentSelectConfigurationsDialog.html"/>
<bs:refreshable containerId="agentSelectConfigurationsContainer" pageUrl="${actionUrl}">
  <bs:modalDialog formId="agentSelectConfigurations"
                  title="Assign Build Configurations to Agent"
                  action="${actionUrl}"
                  closeCommand="BS.AgentSelectConfigurationsDialog.close()"
                  saveCommand="BS.AgentSelectConfigurationsDialog.filterConfigurations()"
                  dialogClass="modalDialog_large">

    <c:choose>
      <c:when test="${bean.error}">
        <bs:refreshable containerId="configurationListRefreshable" pageUrl="${actionUrl}">
          <div class="error">${bean.errorMessage}</div>
          <div class="popupSaveButtonsBlock">
            <forms:submit type="button" label="Close" onclick="BS.AgentSelectConfigurationsDialog.closeAndRefresh()"/>
          </div>
        </bs:refreshable>
      </c:when>
      <c:otherwise>
        <input name="agentTypeId" value="${agentTypeId}" type="hidden"/>

        <div class="actionBar">
          <span class="nowrap">
            <label for="searchString">Name:</label>
            <forms:textField name="searchString" size="20" maxlength="1024" value="${bean.searchString}"/>
          </span>

          <input class="btn btn_mini" type="submit" name="submitFilter" value="Search"/>
          <forms:saving id="findProgress" className="progressRingInline"/>
        </div>

        <bs:refreshable containerId="configurationListRefreshable" pageUrl="${actionUrl}">
          <c:set var="configurations" value="${bean.configurations}"/>
          <c:set var="configurationsNum" value="${fn:length(configurations)}"/>
          <c:choose>
            <c:when test="${param.mode == 'filter' && not empty bean.searchString && empty configurations}">
              <p class="note">No build configurations found.</p>
            </c:when>
            <c:when test="${configurationsNum > 0}">
              <c:choose>
                <c:when test="${param.mode == 'filter'}">
                  Found <b><c:out value="${configurationsNum}"/></b> active build configuration<bs:s val="${configurationsNum}"/>:
                </c:when>
                <c:when test="${bean.moreCount > 0}">
                  The first <b><c:out value="${configurationsNum}"/></b> active build configuration<bs:s val="${configurationsNum}"/> are shown.
                  <a href="#" onclick="BS.AgentSelectConfigurationsDialog.showAllConfigurations(); return false">Show all (<c:out value="${configurationsNum + bean.moreCount}"/>)</a>
                </c:when>
                <c:when test="${param.mode == 'showAll' && bean.moreCount == 0}">
                  All <b><c:out value="${configurationsNum}"/></b> active build configuration<bs:s val="${configurationsNum}"/>:
                </c:when>
              </c:choose>
              <table class="configurationList">
                <tr>
                  <th class="checkbox">
                    <forms:checkbox name="selectAll"
                                    onmouseover="BS.Tooltip.showMessage(this, {shift: {x: 10, y: 20}, delay: 600}, 'Click to select / unselect all build configurations')"
                                    onmouseout="BS.Tooltip.hidePopup()"
                                    onclick="if (this.checked) BS.AgentSelectConfigurationsDialog.selectAll(true); else BS.AgentSelectConfigurationsDialog.selectAll(false)"/>
                  </th>
                  <th class="configurationName">Build configuration</th>
                </tr>
                <tr>
                  <td colspan="2" style="padding: 0">
                    <div class="configurationListContainer custom-scroll">
                      <table>
                        <c:forEach items="${configurations}" var="configuration">
                          <c:set var="trClass" value="unchecked"/>
                          <c:if test="${configuration.selected}"><c:set var="trClass" value="checked"/></c:if>
                          <tr id="dialog-configuration-row${configuration.buildType.id}" class="${trClass}">
                            <td class="checkbox">
                              <forms:checkbox name="selectedConfigurations" id="selectedConfigurations_${configuration.buildType.id}" value="${configuration.buildType.id}" checked="${configuration.selected}"
                                  onclick="BS.AgentSelectConfigurationsDialog.selectBuildType('dialog-configuration-row${configuration.buildType.id}', this.checked)"/>
                            </td>
                            <td>
                              <bs:buildTypeLinkFull buildType="${configuration.buildType}"/>
                            </td>
                          </tr>
                        </c:forEach>
                      </table>
                    </div>
                  </td>
                </tr>
              </table>
            </c:when>
            <c:when test="${configurationsNum == 0}">
              <p class="note" style="font-style: italic">All build configurations are already assigned</p>
            </c:when>
          </c:choose>

          <div class="popupSaveButtonsBlock">
            <forms:submit type="button" label="Assign" onclick="BS.AgentSelectConfigurationsDialog.submit()"/>
            <forms:cancel onclick="BS.AgentSelectConfigurationsDialog.close()" showdiscardchangesmessage="false"/>
            <forms:saving id="addProgress"/>
          </div>
        </bs:refreshable>
      </c:otherwise>
    </c:choose>

  </bs:modalDialog>
</bs:refreshable>