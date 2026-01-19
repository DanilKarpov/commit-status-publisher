<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="canManageLicenses" value="${afn:permissionGrantedGlobally('MANAGE_SERVER_LICENSES')}"/>
<c:choose>
  <c:when test="${healthStatusItem.identity == 'maintenanceExpiring'}">
    <c:set var="numKeys" value="${healthStatusItem.additionalData['numKeys']}"/>
    <c:set var="numExpiringKeys" value="${healthStatusItem.additionalData['numExpiringKeys']}"/>
    <c:set var="numExpiredKeys" value="${healthStatusItem.additionalData['numExpiredKeys']}"/>
    <c:set var="expireDays" value="${healthStatusItem.additionalData['maintenanceExpireDays']}"/>

    <c:set var="licenseLink">
      <c:if test="${canManageLicenses}"><a href="<c:url value='/admin/admin.html?item=license'/>">license</a></c:if>
      <c:if test="${not canManageLicenses}">license</c:if>
    </c:set>
    <c:set var="licensesLink">
      <c:if test="${canManageLicenses}"><a href="<c:url value='/admin/admin.html?item=license'/>">licenses</a></c:if>
      <c:if test="${not canManageLicenses}">licenses</c:if>
    </c:set>

    <c:if test="${numExpiredKeys > 0}">
      The maintenance period for
      <c:choose><c:when test="${numExpiredKeys > 1 && numExpiredKeys == numKeys}">all</c:when><c:when test="${numExpiredKeys == 1 && numKeys == 1}">the</c:when><c:otherwise>${numExpiredKeys} of ${numKeys}</c:otherwise></c:choose>
      TeamCity
      <c:choose><c:when test="${numExpiredKeys == 1}">${licenseLink}</c:when><c:otherwise>${licensesLink}</c:otherwise></c:choose>
      has expired.
      <br/>
    </c:if>

    <c:if test="${numExpiringKeys > 0}">
      The maintenance period for
      <c:choose><c:when test="${numExpiringKeys > 1 && numExpiringKeys == numKeys}">all</c:when><c:when test="${numExpiringKeys == 1 && numKeys == 1}">the</c:when><c:otherwise>${numExpiringKeys} of ${numKeys}</c:otherwise></c:choose>
      TeamCity
      <c:choose><c:when test="${numExpiringKeys == 1}">${licenseLink}</c:when><c:otherwise>${licensesLink}</c:otherwise></c:choose>
      expires within ${expireDays} day<bs:s val="${expireDays}"/>.
      <br/>
    </c:if>
    It is recommended to upgrade the license in order to be able to use TeamCity support and upgrade to newer TeamCity releases.
  </c:when>
  <c:when test="${healthStatusItem.identity == 'trialExpiring'}">
    <c:set var="daysToExpiration" value="${healthStatusItem.additionalData['daysToExpiration']}"/>
    The TeamCity license
    <c:if test="${canManageLicenses}"><a href="<c:url value='/admin/admin.html?item=license'/>">will expire in ${daysToExpiration} day<bs:s val="${daysToExpiration}"/></a>.</c:if>
    <c:if test="${not canManageLicenses}">will expire in ${daysToExpiration} day<bs:s val="${daysToExpiration}"/>.</c:if>
    <br/>
    After the expiration, TeamCity will run in Professional mode and
    <bs:helpLink file="Licensing+Policy" anchor="LicenseExpiration">several important restrictions</bs:helpLink>
    will be applied.
  </c:when>
  <c:when test="${healthStatusItem.category.id == 'buildTypesLimitApproaching'}">
    <c:set var="currentBuildTypesNum" value="${healthStatusItem.additionalData['currentBuildTypesNum']}"/>
    <c:set var="licensedBuildTypesNum" value="${healthStatusItem.additionalData['licensedBuildTypesNum']}"/>
    The number of build configurations (<strong>${currentBuildTypesNum}</strong>) ${currentBuildTypesNum < licensedBuildTypesNum ? 'can soon reach ' : 'reached '} the maximum (<strong>${licensedBuildTypesNum}</strong>).
    <br/>
    Please consider purchasing additional <a href="https://www.jetbrains.com/teamcity/buy" target="_blank" rel="noreferrer">TeamCity Agent license</a> to increase the build configurations limit,
    or <a href="https://www.jetbrains.com/teamcity/buy" target="_blank" rel="noreferrer">TeamCity Enterprise license</a> to remove the limit completely.
  </c:when>
  <c:when test="${healthStatusItem.category.id == 'pipelinesLimitApproaching'}">
    <c:set var="currentPipelinesNum" value="${healthStatusItem.additionalData['currentPipelinesNum']}"/>
    <c:set var="licensedPipelinesNum" value="${healthStatusItem.additionalData['licensedPipelinesNum']}"/>
    The number of pipelines (<strong>${currentPipelinesNum}</strong>) ${currentPipelinesNum < licensedPipelinesNum ? 'can soon reach ' : 'reached '} the maximum (<strong>${licensedPipelinesNum}</strong>).
    <br/>
    Please consider purchasing <a href="https://www.jetbrains.com/teamcity/buy" target="_blank" rel="noreferrer">TeamCity Enterprise license</a> to remove the limit.
  </c:when>
  <c:when test="${healthStatusItem.category.id == 'perUsageLimitError'}">
    <authz:authorize anyPermission="MANAGE_SERVER_LICENSES">
      <jsp:attribute name="ifAccessGranted">
        Failed to send server usage data to the JetBrains Account server. Your per-usage Enterprise license has been suspended.
      </jsp:attribute>
      <jsp:attribute name="ifAccessDenied">
        Per-usage Enterprise license has been suspended. Please contact your server administrator.
      </jsp:attribute>
    </authz:authorize>
  </c:when>
  <c:when test="${healthStatusItem.category.id == 'perUsageLimitWarning'}">
    <authz:authorize anyPermission="MANAGE_SERVER_LICENSES">
      <jsp:attribute name="ifAccessGranted">
        Failed to send server usage data to the JetBrains Account server. Your per-usage Enterprise license will be suspended <c:out value="${healthStatusItem.additionalData['timeToSuspend']}"/> unless communication is established.
      </jsp:attribute>
      <jsp:attribute name="ifAccessDenied">
        Per-usage Enterprise license will be suspended soon. Please contact your server administrator.
      </jsp:attribute>
    </authz:authorize>
  </c:when>
  <c:when test="${healthStatusItem.category.id == 'perUsageUnsuccessful'}">
    <authz:authorize anyPermission="MANAGE_SERVER_LICENSES">
      <jsp:attribute name="ifAccessGranted">
        Failed to send server usage data to the JetBrains Account server. Your per-usage Enterprise license will be suspended <c:out value="${healthStatusItem.additionalData['timeToSuspend']}"/> unless communication is established.
      </jsp:attribute>
    </authz:authorize>
  </c:when>
  <c:when test="${healthStatusItem.category.id == 'licenseLimitsExceeded'}">
    <c:choose>
      <c:when test="${healthStatusItem.identity == 'numberOfAuthorizedAgentsExceeded'}">
        <c:set var="licensedAgentsNum" value="${healthStatusItem.additionalData['licensedAgentsNum']}"/>

        <authz:authorize anyPermission="MANAGE_SERVER_LICENSES">
          <jsp:attribute name="ifAccessGranted">
            The maximum number of authorized agents (<strong>${licensedAgentsNum}</strong>) exceeded.
            <strong>Builds won't run</strong> until you unauthorize some agents or
            <c:if test="${canManageLicenses}"><a href="<c:url value='/admin/admin.html?item=license'/>">enter additional licenses</a></c:if>
            <c:if test="${not canManageLicenses}">enter additional licenses</c:if>.<bs:help file="Licensing+Policy" anchor="WaystoObtainaLicense"/>
          </jsp:attribute>
          <jsp:attribute name="ifAccessDenied">
            Builds are not run because the maximum number of authorized agents exceeded. Please contact your server administrator.
          </jsp:attribute>
        </authz:authorize>

      </c:when>
      <c:when test="${healthStatusItem.identity == 'numberOfBuildTypesExceeded'}">
        <c:set var="currentBuildTypesNum" value="${healthStatusItem.additionalData['currentBuildTypesNum']}"/>
        <c:set var="licensedBuildTypesNum" value="${healthStatusItem.additionalData['licensedBuildTypesNum']}"/>

        <authz:authorize anyPermission="MANAGE_SERVER_LICENSES">
          <jsp:attribute name="ifAccessGranted">
            This TeamCity installation has <strong>${currentBuildTypesNum}</strong> build configurations. Only <strong>${licensedBuildTypesNum}</strong> configurations are allowed.
            <br><strong>Builds won't run</strong> until you either remove extra build configurations or
            <c:if test="${canManageLicenses}"><a href="<c:url value='/admin/admin.html?item=license'/>">enter additional licenses</a>.</c:if>
            <c:if test="${not canManageLicenses}">enter additional licenses.</c:if><bs:help file="Licensing+Policy" anchor="WaystoObtainaLicense"/>
          </jsp:attribute>
          <jsp:attribute name="ifAccessDenied">
            Builds are not run because the maximum number of build configurations exceeded. Please contact your server administrator.
          </jsp:attribute>
        </authz:authorize>

      </c:when>
      <c:when test="${healthStatusItem.identity == 'numberOfPipelinesExceeded'}">
        <c:set var="currentPipelinesNum" value="${healthStatusItem.additionalData['currentPipelinesNum']}"/>
        <c:set var="licensedPipelinesNum" value="${healthStatusItem.additionalData['licensedPipelinesNum']}"/>

        <authz:authorize anyPermission="MANAGE_SERVER_LICENSES">
          <jsp:attribute name="ifAccessGranted">
            This TeamCity installation has <strong>${currentPipelinesNum}</strong> pipelines. Only <strong>${licensedPipelinesNum}</strong> pipelines are allowed.
            <br><strong>Builds won't run</strong> until you either remove extra pipelines or
            <c:if test="${canManageLicenses}"><a href="<c:url value='/admin/admin.html?item=license'/>">enter additional licenses</a>.</c:if>
            <c:if test="${not canManageLicenses}">enter additional licenses.</c:if><bs:help file="Licensing+Policy" anchor="WaystoObtainaLicense"/>
          </jsp:attribute>
          <jsp:attribute name="ifAccessDenied">
            Builds are not run because the maximum number of pipelines exceeded. Please contact your server administrator.
          </jsp:attribute>
        </authz:authorize>

      </c:when>
    </c:choose>
  </c:when>
  <c:when test="${healthStatusItem.identity == 'invalidJwtLicense'}">
    <c:set var="gracePeriodEnd" value="${healthStatusItem.additionalData['gracePeriodEnd']}"/>
    <authz:authorize anyPermission="MANAGE_SERVER_LICENSES">
      <jsp:attribute name="ifAccessGranted">
        The current JetBrains Accounts license had become invalid. It will be disabled at <c:out value="${gracePeriodEnd}"/>.
        Please upload a new license or refresh the current one.

        <c:if test="${canManageLicenses}">
          To update current license please visit <a href="<c:url value='/admin/admin.html?item=license'/>">licenses page</a>.
        </c:if>
      </jsp:attribute>
      <jsp:attribute name="ifAccessDenied">
        The current JetBrains Accounts license is invalid and will be disabled soon. Please contact your server administrator.
      </jsp:attribute>
  </authz:authorize>
  </c:when>
</c:choose>