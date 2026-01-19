<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@include file="/include-internal.jsp"%>
<c:set var="pageTitle" value="License Agreement"/>
<bs:externalPage>
  <jsp:attribute name="page_title">${pageTitle}</jsp:attribute>
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/forms.css
      /css/maintenance-initialPages-common.css
      /css/initialPages.css
    </bs:linkCSS>
    <script>
      ReactUI.setGlobalTheme();
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <bs:_loginPageDecoration id="agreementPage" title="License Agreement for JetBrains<sup>&reg;</sup> TeamCity<sup>&reg;</sup>">
      <div class="agreementPage">
        <div class="agreement">
        <jsp:include page="/license/agreement.jsp"/>
        </div>
        <div class="agreementForm clearfix">
          <form action="${pageUrl}" method="post" onsubmit="if (!this.accept.checked) { alert('Please accept the license agreement'); return false; };">
            <div class="license-agreement-checkbox-wrapper">
              <forms:checkbox name="accept"/><label for="accept" class="rightLabel">Accept license agreement</label>
            </div>
            <ext:includeExtensions placeId="<%=PlaceId.ACCEPT_LICENSE_SETTING%>"/>
            <div class="continueBlock">
              <forms:submit label="Continue &raquo;" name="Continue" disabled="${true}"/>
            </div>
            <script>
              (function () {
                var $submit = $j('.submitButton');
                var $accept = $j('#accept');

                function enableSubmitIfLicenseAccepted() {
                  $submit.prop('disabled', !$accept.prop('checked'));
                }
                $accept.on('click', enableSubmitIfLicenseAccepted);
                enableSubmitIfLicenseAccepted();
              })();
            </script>
          </form>
        </div>
      </div>
    </bs:_loginPageDecoration>
  </jsp:attribute>
</bs:externalPage>
