<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<jsp:useBean id="generateTokenMode" scope="request" type="java.lang.Boolean"/>
<c:choose>
  <c:when test="${generateTokenMode}">
    <c:set var="dialogTitle" value="Generate Token"/>
    <c:set var="actionTitle" value="Generate token for a secure value..."/>
    <c:set var="buttonTitle" value="Generate Token"/>
    <c:set var="generatedTokenNote"
           value="Enter secure value you'd like to generate token for below. Generated token will be stored on the server and can be used in project configuration files instead of the secure value."/>
  </c:when>
  <c:otherwise>
    <c:set var="dialogTitle" value="Scramble Secure Value"/>
    <c:set var="actionTitle" value="Scramble secure value..."/>
    <c:set var="buttonTitle" value="Scramble"/>
    <c:set var="generatedTokenNote"
           value="Enter secure value you'd like to scramble below. Scrambled value can be safely used in project configuration files instead of the secure value."/>
  </c:otherwise>
</c:choose>
<c:url var="generateAction" value="/admin/action.html"/>
<l:li>
  <a href="#" onclick="return BS.GenerateTokenForm.showDialog('${project.externalId}')">${actionTitle}</a>
  <bs:executeOnce id="generateTokenDialog">
    <bs:modalDialog formId="generateTokenForm"
                    title="${dialogTitle}"
                    action=""
                    closeCommand="BS.GenerateTokenForm.close()"
                    saveCommand="false">
      <div class="grayNote" style="width: auto; margin-bottom: 1em;">
        <c:out value="${generatedTokenNote}"/>

        <a
            href="https://www.jetbrains.com/help/teamcity/storing-project-settings-in-version-control.html#StoringProjectSettingsinVersionControl-StoringSecureSettings"
            rel="nofollow noreferrer"
            target="_blank"
            class="actionIconWrapper"
            showdiscardchangesmessage="false"
        ><bs:helpIcon/></a>
      </div>

      <label for="secureValue" class="tableLabel">Secure value:</label>
      <forms:passwordField name="secureValue" className="longField" expandable="true"/>
      <input type="hidden" name="projectId" value=""/>

      <div>
        <span class="clipboard-btn tc-icon icon16 tc-icon_copy" style="float: left" data-clipboard-action="copy" data-clipboard-target="#generatedToken"></span>
        <div id="generatedToken" class="mono"></div>
      </div>

      <div class="popupSaveButtonsBlock">
        <forms:button id="generateTokenButton" onclick="BS.GenerateTokenForm.generateToken(); return false;" className="btn_primary">${buttonTitle}</forms:button>
        <forms:button id="generateTokenCloseButton" onclick="BS.GenerateTokenForm.close(); return false;">Close</forms:button>
        <forms:saving id="generateTokenProgress"/>
      </div>
      <script type="text/javascript">
        BS.GenerateTokenForm = OO.extend(BS.AbstractModalDialog, {
          generatedToken: false,

          getContainer: function() {
            return $j('#generateTokenFormDialog')[0];
          },

          showDialog: function (projectId, reloadAfterClose) {
            this.reloadAfterClose = reloadAfterClose;

            this.showCentered();
            this.newToken();
            $j('#generateTokenForm input[name="projectId"]').attr('value', projectId);
            $j('#generateTokenForm .clipboard-btn').hide();
            BS.Clipboard('#generateTokenFormDialog span.clipboard-btn');

            return false;
          },

          generateToken: function () {
            this.generatedToken = true;

            $j('#generatedToken').text('');
            $j('#generateTokenProgress').show();

            var projectId = $j('#generateTokenForm input[name="projectId"]').val();
            var secureVal = $j('#generateTokenForm textarea[name="secureValue"]').val();

            BS.ajaxRequest('${generateAction}', {
              parameters: "generateToken=true&projectId=" + projectId + "&secureValue=" + encodeURIComponent(secureVal),
              onComplete: function(transport) {
                $j('#generateTokenProgress').hide();
                var root = transport.responseXML;
                if (root) {
                  var elems = root.getElementsByTagName('token');
                  var tokenEl = elems[0];
                  $j('#generatedToken').text(tokenEl.firstChild.nodeValue);
                  $j('#generateTokenForm .clipboard-btn').show();

                  $j('#generateTokenButton').hide();
                  $j('#generateTokenNewButton').show();
                }
              }
            });
            return false;
          },

          newToken: function () {
            $j('#generateTokenForm textarea[name="secureValue"]').val('');
            $j('#generateTokenForm textarea[name="secureValue"]').focus();
            $j('#generatedToken').text('');
            $j('#generateTokenForm .clipboard-btn').hide();
            $j('#generateTokenNewButton').hide();
            $j('#generateTokenButton').show();
          },

          afterClose: function () {
            if (this.reloadAfterClose && this.generatedToken) {
              BS.reload(true);
            }
          }
        });
      </script>
    </bs:modalDialog>
  </bs:executeOnce>
</l:li>
