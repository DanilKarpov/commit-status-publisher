<%@ page import="jetbrains.buildServer.serverSide.impl.BuildServerImpl" %><%--@elvariable id="serverLicenseBean" type="jetbrains.buildServer.controllers.license.ServerLicenseBean"--%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout"%>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags"%>
<div class="inactiveLicensesContainer">
  <l:blockStateCss blocksType="Block_inactiveLicenses" collapsedByDefault="false" id="editInactiveLicenses"/>

  <p class="icon_before icon16 blockHeader expanded" id="inactiveLicenses">Inactive license keys: ${fn:length(serverLicenseBean.inactiveLicenses)}</p>
  <form action="#" id="editInactiveLicenses">
    <table class="settings licensesTable inactiveLicensesTable" id="inactiveLicensesTable">
      <tr>
        <th class="name licenseKey">License key</th>
        <th class="name description">Description</th>
        <c:if test="${!serverLicenseBean.readOnly}">
          <th class="name edit"><forms:checkbox name="selectAllInaciveCB" onclick="if (this.checked) BS.Util.selectAll($('editInactiveLicenses'), 'removeKeyCB'); else BS.Util.unselectAll($('editInactiveLicenses'), 'removeKeyCB');"/></th>
        </c:if>
      </tr>
      <c:forEach items="${serverLicenseBean.inactiveLicenses}" var="lic">
        <tr>
          <td><c:out value="${lic.key}"/></td>
          <td>
            <c:if test="${fn:length(lic.notCompatibleNewVersions) > 0}">
              <span title="The license will become obsolete after upgrade to <c:forEach items="${lic.notCompatibleNewVersions}" var="ver" varStatus="status">${ver.version}<c:if test="${!status.last}">, </c:if></c:forEach>"
                ><bs:buildStatusIcon type="red-sign" className="warningIcon"
              /></span>
            </c:if>
            <c:choose>
              <c:when test="${not lic.recognized}">Invalid key</c:when>
              <c:when test="${lic.recognized}">
                <strong><c:out value="${lic.licenseName}"/></strong>,
                <c:choose>
                  <c:when test="${not empty lic.expirationDate}">expires: <bs:formatDate value="${lic.expirationDate}" pattern="yyyy-MM-dd"/></c:when>
                  <c:otherwise>end of maintenance: <bs:formatDate value="${lic.maintenanceDueDate}" pattern="yyyy-MM-dd"/></c:otherwise>
                </c:choose>

                <c:if test="${lic.licenseExpired}"> (<span class="expired">expired</span>)</c:if>
                <c:if test="${lic.licenseObsolete}"> (<span class="expired">obsolete</span>)</c:if>
              </c:when>
            </c:choose>
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
        <a href="#" class="remove btn" onclick="BS.LicensesForm.removeLicenseKeys(BS.Util.getSelectedValues($('editInactiveLicenses'), 'removeKeyCB'));return false">Remove selected</a>
      </div>
    </c:if>
  </form>

  <script type="text/javascript">
    <l:blockState blocksType="Block_inactiveLicenses"/>
    new BS.BlocksWithHeader('inactiveLicenses');
  </script>

  <br/>
</div>