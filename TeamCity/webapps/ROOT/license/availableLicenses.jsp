<%@ page import="jetbrains.buildServer.serverSide.impl.BuildServerImpl" %><%--@elvariable id="serverLicenseBean" type="jetbrains.buildServer.controllers.license.ServerLicenseBean"--%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms"%>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<h3 class="title_underlined">Active license keys</h3>

<c:if test="${fn:length(serverLicenseBean.newVersionsNotCompatibleWithSomeLicense) > 0}">
  <div id="notCompatibleLicensesWarn" class="attentionComment">
    <bs:buildStatusIcon type="red-sign" className="warningIcon"/>New TeamCity version<bs:s val="${fn:length(serverLicenseBean.newVersionsNotCompatibleWithSomeLicense)}"/> <bs:are_is
      val="${fn:length(serverLicenseBean.newVersionsNotCompatibleWithSomeLicense)}"/> available, maintenance period of some licenses does not cover the new version<bs:s val="${fn:length(serverLicenseBean.newVersionsNotCompatibleWithSomeLicense)}"/> release date and the licenses require renewal before the upgrade.
    <div class="notCompatibleModeSelectors">
      <span>Show:</span>
      <div>
        <forms:radioButton name="displayMode" id="allLicenses" checked="${true}" onclick="BS.LicensesForm.toggleIncompatibleWith()"/>
        <label for="allLicenses">all licenses</label>
      </div>
      <c:forEach items="${serverLicenseBean.newVersionsNotCompatibleWithSomeLicense}" var="notCompatibleVersion">
        <div>
          <c:set var="onclick">BS.LicensesForm.toggleIncompatibleWith('${util:forJSIdentifier(notCompatibleVersion.version)}')</c:set>
          <forms:radioButton name="displayMode" id="notCompatibleWithMode_${util:forJSIdentifier(notCompatibleVersion.version)}" onclick='${onclick}'/>
          <label for="notCompatibleWithMode_${util:forJSIdentifier(notCompatibleVersion.version)}">incompatible with TeamCity ${notCompatibleVersion.version},
          effective release date <bs:formatDate value="${notCompatibleVersion.releasedDate}" pattern="yyyy-MM-dd"/></label>
        </div>
      </c:forEach>
    </div>
  </div>
</c:if>


<form action="#" id="editActiveLicenses">
  <table id="availableLicensesList" class="settings licensesTable">
    <tr>
      <th class="name licenseKey">License key</th>
      <th class="name">Type</th>
      <th class="name numAgents" ># of agents</th>
      <th class="name numConfs" ># of build configurations</th>
      <th class="name generationDate">Generation date</th>
      <th class="name subscriptionDate">End of maintenance</th>
      <th class="name expirationDate">Expiration date</th>
      <c:if test="${!serverLicenseBean.readOnly}">
        <th class="name edit"><forms:checkbox name="selectAllActiveCB" onclick="if (this.checked) BS.Util.selectAll($('editActiveLicenses'), 'removeKeyCB'); else BS.Util.unselectAll($('editActiveLicenses'), 'removeKeyCB');"/></th>
      </c:if>
    </tr>
    <c:forEach items="${serverLicenseBean.licenses}" var="lic">
      <tr class="<c:forEach items="${lic.notCompatibleNewVersions}" var="ver" varStatus="status">notCompatibleWith_${util:forJSIdentifier(ver.version)}<c:if test="${!status.last}"> </c:if></c:forEach>">
        <td class="licenseKey">
          ${lic.key}
        </td>
        <td class="licenseType">
          <strong><c:out value="${lic.licenseName}"/></strong>
        </td>
        <td class="numAgents"><c:out value='${lic.numberOfAgents}'/></td>
        <td class="numConfs"><c:out value='${lic.numberOfConfigurations}'/></td>
        <td class="generationDate"><bs:formatDate value="${lic.generationDate}" pattern="yyyy-MM-dd"/></td>
        <td class="subscriptionDate">
          <c:if test="${lic.maintenanceExpired || lic.maintenanceExpiringSoon || fn:length(lic.notCompatibleNewVersions) > 0}">
            <c:set var="warningContent">
              <c:choose>
                <c:when test="${fn:length(lic.notCompatibleNewVersions) > 0}">
                  <div>
                    The license needs renewing before upgrade to <c:forEach items="${lic.notCompatibleNewVersions}" var="ver" varStatus="status">${ver.version}<c:if test="${!status.last}">, </c:if></c:forEach>
                  </div>
                </c:when>
                <c:when test="${lic.maintenanceExpired}">
                  <div>Maintenance is expired</div>
                </c:when>
                <c:when test="${not lic.maintenanceExpired and lic.maintenanceExpiringSoon}">
                  <div>Maintenance is expiring soon</div>
                </c:when>
              </c:choose>
            </c:set>
            <span <bs:tooltipAttrs text="${warningContent}"></bs:tooltipAttrs>
              ><bs:buildStatusIcon type="red-sign" className="warningIcon"
            /></span>
          </c:if>
          <bs:formatDate value="${lic.maintenanceDueDate}" pattern="yyyy-MM-dd"/>
        </td>
        <td class="expirationDate">
          <c:choose>
            <c:when test="${not empty lic.expirationDate}">
              <c:if test="${lic.expiringSoon}"
                ><span title="License is expiring soon"
                  ><bs:buildStatusIcon type="red-sign" className="warningIcon"
                /></span
              ></c:if>
              <bs:formatDate value="${lic.expirationDate}" pattern="yyyy-MM-dd"/>
            </c:when>
            <c:otherwise>N/A</c:otherwise>
          </c:choose>
          <c:if test="${lic.licenseExpired}"> (<span class="expired">expired</span>)</c:if>
        </td>
        <c:if test="${!serverLicenseBean.readOnly}">
          <td class="edit">
            <c:set var="keyEscaped"><bs:escapeForJs text='${lic.key}' forHTMLAttribute='true'/></c:set>
            <forms:checkbox name="removeKeyCB" value="${keyEscaped}"/>
          </td>
        </c:if>
      </tr>
    </c:forEach>
  </table>

  <c:if test="${!serverLicenseBean.readOnly}">
    <div class="licensesActions">
      <a href="#" class="remove btn" onclick="BS.LicensesForm.removeLicenseKeys(BS.Util.getSelectedValues($('editActiveLicenses'), 'removeKeyCB'));return false">Remove selected</a>
    </div>
  </c:if>
</form>


<script type="text/javascript">
  BS.LicensesForm.initFromHash();
</script>
