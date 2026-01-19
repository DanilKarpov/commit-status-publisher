<%@include file="/include-internal.jsp"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags"%>
<%@ taglib prefix="forms" tagdir="/WEB-INF/tags/forms"%>
<%@ taglib prefix="l" tagdir="/WEB-INF/tags/layout"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<jsp:useBean id="serverLicenseBean" type="jetbrains.buildServer.controllers.license.ServerLicenseBean" scope="request"/>
<jsp:useBean id="releaseDate" type="java.util.Date" scope="request"/>
<c:set var="currentTab" value="licenses" scope="request"/>

<bs:linkScript>
  /js/bs/locationHash.js
</bs:linkScript>

<c:choose>
  <c:when test="${intprop:getBooleanOrTrue('teamcity.ui.newLicensesPage')}">
    <div id="licensesPage"></div>
    <script>
      ReactUI.renderLicensesPage('licensesPage')
    </script>
    <c:if test="${serverLicenseBean.encounteredExecutorBuild}">
      <div id="experimentalFeatureDisclaimer">
        <br/>
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>
        This server is using Kubernetes executor(s) to run builds. Note that each build started by Kubernetes executor occupies a build agent license.
      </div>
    </c:if>
  </c:when>
  <c:otherwise>
    <div class="licensesPage clearfix">
      <div id="pageContent">
        <div>
          <c:set var="prefix">TeamCity ${serverTC.fullServerVersion}, effective release date <bs:formatDate value="${releaseDate}" pattern="yyyy-MM-dd"/></c:set>

          <bs:refreshable containerId="licensePage" pageUrl="${pageUrl}">
            <c:choose>
              <c:when test="${serverLicenseBean.enterpriseLicenseAvailable and not serverLicenseBean.trialMode}">
                <div class="licenseMode">
                    ${prefix}, currently running in the <strong>enterprise</strong> mode.<bs:help file="Licensing+Policy"/>
                </div>
              </c:when>
              <c:when test="${not serverLicenseBean.enterpriseLicenseAvailable}">
                <div class="licenseMode">
                    ${prefix}, currently running in the <strong>professional</strong> mode.<bs:help file="Licensing+Policy"/>
                </div>
              </c:when>
              <c:when test="${serverLicenseBean.trialMode}">
                <div class="licenseMode">
                    ${prefix}, currently running in the <strong>evaluation</strong> mode.<bs:help file="Licensing+Policy"/>
                </div>
              </c:when>
            </c:choose>

            <c:set value="${serverLicenseBean.licensedAgentCount - serverLicenseBean.numberOfPredefinedAgents}" var="additionalBuildAgents"/>
            <p>Maximum number of authorized agents: <c:choose>
              <c:when test="${serverLicenseBean.unlimitedAgents}"><strong>unlimited</strong></c:when>
              <c:otherwise>
                <strong>${serverLicenseBean.licensedAgentCount}</strong> agent<bs:s val="${serverLicenseBean.licensedAgentCount}"/>

                <c:if test="${additionalBuildAgents == 0}">provided by professional edition license</c:if>
                <c:if test="${additionalBuildAgents > 0 and not serverLicenseBean.enterpriseLicenseAvailable}">(${serverLicenseBean.numberOfPredefinedAgents} provided by professional edition license + ${additionalBuildAgents} provided by license keys)</c:if>

              </c:otherwise>
            </c:choose>
            </p>

            <c:set value="${serverLicenseBean.licensedBuildTypesCount - serverLicenseBean.numberOfPredefinedBuildTypes}" var="additionalBuildTypes"/>
            <p>Maximum number of build configurations: <c:choose>
              <c:when test="${serverLicenseBean.unlimitedBuildTypes}"><strong>unlimited</strong></c:when>
              <c:otherwise>
                <strong>${serverLicenseBean.licensedBuildTypesCount}</strong> build configuration<bs:s val="${serverLicenseBean.licensedBuildTypesCount}"/>

                <c:if test="${additionalBuildTypes == 0}">provided by professional edition license</c:if>
                <c:if test="${additionalBuildTypes > 0}">(${serverLicenseBean.numberOfPredefinedBuildTypes} provided by professional edition license + ${additionalBuildTypes} provided by license keys)</c:if>

              </c:otherwise>
            </c:choose>
            </p>

            <bs:messages key="licenseKeyRemoved" style="margin-left: 0;"/>
            <bs:messages key="licenseKeysAdded" style="margin-left: 0;"/>

            <c:set var="displayLinks" value="${not serverLicenseBean.enterKeysMode ? 'block' : 'none'}"/>
            <c:if test="${!serverLicenseBean.readOnly}">
              <div class="newLicense" id="newLicense" style="display: ${displayLinks}">
                <c:url value='/admin/admin.html?item=license&enterKeys=true' var="licenseUrl"/>
                <forms:addButton onclick="BS.LicensesForm.showEmptyForm()">Enter new license(s)</forms:addButton>
              </div>
            </c:if>

            <c:set var="displayForm" value="${serverLicenseBean.enterKeysMode ? 'block' : 'none'}"/>
            <form id="licensesForm" action="<c:url value='/admin/licenses.html'/>" style="display: ${displayForm}" method="post">

              <h2>Enter TeamCity License Keys</h2>

              <p class="licenseMessage">
                Please enter license keys below (place each license key on a separate line):
              </p>

              <textarea id="licenseKeys" name="licenseKeys" rows="5" cols="75">${serverLicenseBean.licenseKeys}</textarea>

              <div style="margin-top: 1em">
                <a class="btn btn_primary" href="#" id="saveKeys" name="saveKeys" onclick="BS.LicensesForm.submitLicenses(); return false">Save</a>
                <a class="btn" onclick="BS.LicensesForm.hideEmptyForm(); return false;" href="#">Cancel</a>
              </div>

              <input type="hidden" id="enterKeys" name="enterKeys" value="true"/>
              <input type="hidden" id="submitKeys" name="submitKeys" value="Save"/>
            </form>

            <div id="verificationStatus"></div>
            <div class="error"></div>

            <c:if test="${serverLicenseBean.perUsageMode}">
              <h3 class="title_underlined">Server usage data</h3>
              <div>
                <jsp:include page="/admin/perUsageLicenseDataController.html"/>
              </div>
            </c:if>

            <c:if test="${serverLicenseBean.licenseKeysExist}">
              <jsp:include page="/license/availableLicenses.jsp"/>
            </c:if>

            <c:if test="${not empty serverLicenseBean.inactiveLicenses}">
              <jsp:include page="/license/inactiveLicenses.jsp"/>
            </c:if>
          </bs:refreshable>

          <c:if test="${serverLicenseBean.encounteredExecutorBuild}">
            <div id="experimentalFeatureDisclaimer">
              <br/>
              <bs:buildStatusIcon type="red-sign" className="warningIcon"/>
              This server is using Kubernetes executor(s) to run builds. Note that each build started by Kubernetes executor occupies a build agent license.
            </div>
          </c:if>

        </div>
      </div>
    </div>

    <script type="text/javascript">
      <c:if test="${serverLicenseBean.enterKeysMode}">
      $j(document).ready(function() {
        if ($("licenseKeys")) {
          $("licenseKeys").focus();
        }
      });
      </c:if>
    </script>
  </c:otherwise>
</c:choose>
