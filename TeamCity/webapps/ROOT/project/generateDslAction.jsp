<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.impl.ProjectEx"/>
<jsp:useBean id="relativeIdSupport" type="java.util.Map<String, java.util.Map<String, Boolean>>" scope="request"/>
<jsp:useBean id="formats" type="java.util.List<jetbrains.buildServer.serverSide.impl.versionedSettings.ProjectSettingsGenerator>" scope="request"/>
<c:set var="showNonPortableDSLOption" value="${project.getBooleanInternalParameter('kotlinDsl.newProjects.allowUsingNonPortableDSL')}"/>
<style type="text/css">
  #downloadSettingsFormErrorsDiv {
    display: none;
    margin-left: 0;
  }
</style>
<c:forEach var="format" items="${formats}">
  <l:li>
    <c:set var="menuItem">Download settings in <c:out value="${format.formatDisplayName}"/> format</c:set>
    <c:choose>
      <c:when test="${empty format.versions}">
        <c:url var="genUrl" value="/admin/versionedSettingsActions.html?projectId=${project.externalId}&action=generate&format=${format.format}"/>
        <a href="${genUrl}" title="${menuItem}">${menuItem}</a>
      </c:when>
      <c:otherwise>
        <c:url var="genUrlPrefix" value="/admin/versionedSettingsActions.html?projectId=${project.externalId}&action=generate&format=${format.format}&version="/>
        <c:url var="checkUrlPrefix" value="/admin/versionedSettingsActions.html?projectId=${project.externalId}&action=checkCanGenerate&format=${format.format}&version="/>
        <a href="#" onclick="BS.DownloadSettingsForm.showDialog('${project.externalId}', '${format.formatDisplayName}', '${checkUrlPrefix}', '${genUrlPrefix}', [
          <c:forEach items="${format.versions}" var="version" varStatus="status">
            ['${version}', ${relativeIdSupport[format.format][version]}]<c:if test="${not status.last}">,</c:if>
          </c:forEach>
        ]);" title="${menuItem}...">${menuItem}...</a>
      </c:otherwise>
    </c:choose>
  </l:li>
</c:forEach>
<bs:executeOnce id="downloadSettingsDialog">
  <script type="text/javascript">
    BS.DownloadSettingsForm = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
      formElement: function() {
        return $('downloadSettingsForm');
      },

      getContainer: function() {
        return $j('#downloadSettingsFormDialog')[0];
      },

      showDialog: function(projectId, formatDisplayName, checkUrlPrefix, genUrlPrefix, versions) {
        var i;
        var select = $j("#formatVersion");
        select.find('option').remove();
        for (i = 0; i < versions.length; i++) {
          var versionInfo = versions[i];
          var version = versionInfo[0];
          select.append(
            $j("<option />")
              .val(version)
              .data('supportsRelativeIds', versionInfo[1])
              .text(version.replace(/^v/, '').replace(/_/g, '.'))
          );
        }
        $j('#downloadSettingsCheckUrlPrefix').val(checkUrlPrefix);
        $j('#downloadSettingsGenUrlPrefix').val(genUrlPrefix);
        $j('#downloadSettingsFormTitle').html('Download settings in ' + formatDisplayName + ' format');
        $j('#downloadSettingsFormErrorsDiv').hide();
        this.updateRelativeIds();
        this.showCentered();
      },

      download: function() {
        var version = $j("#formatVersion").val();
        var useRelativeIds = $j('#downloadSettingsUseRelativeIds').is(':checked');
        if ($j('#downloadSettingsUseRelativeIds').prop('type') != 'checkbox') {
          useRelativeIds = $j('#downloadSettingsUseRelativeIds').val();
        }

        BS.Util.disableFormTemp(BS.DownloadSettingsForm.formElement());
        $j('#downloadSettingsFormSaving').show();
        $j('#downloadSettingsFormErrorsDiv').hide();
        $j('#nonUniformIDs').hide();
        BS.ajaxRequest($j('#downloadSettingsCheckUrlPrefix').val() + version + "&useRelativeIds=" + useRelativeIds, {
          onComplete: function(transport) {
            BS.Util.reenableForm(BS.DownloadSettingsForm.formElement());
            $j('#downloadSettingsFormSaving').hide();
            var root = transport.responseXML;
            if (root) {
              var errors = root.getElementsByTagName('error');
              if (errors.length == 0) {
                BS.DownloadSettingsForm.close();
                window.location = $j('#downloadSettingsGenUrlPrefix').val() + version + "&useRelativeIds=" + useRelativeIds;
              } else {
                var errorsList = $j('#downloadSettingsFormErrorsList');
                errorsList.html('');
                for (var i = 0; i < errors.length; i++) {
                  var text = errors[i].textContent;
                  if (text.startsWith('[ERR:nonUniformIDs]: ')) {
                    text = text.substring('[ERR:nonUniformIDs]: '.length);
                    $j('#nonUniformIDs').show();
                  }

                  errorsList.append($j("<li/>").text(text));
                }
                $j('#downloadSettingsFormErrorsDiv').show();
              }
            } else {
              alert('Empty response from the server, check server logs for details');
            }
          }
        });
      },

      updateRelativeIds: function() {
        var selectedVersion = $j("#formatVersion option:selected");
        var checkboxShown = $j('#downloadSettingsUseRelativeIds').prop('type') == 'checkbox';
        if (selectedVersion.data('supportsRelativeIds')) {
          if (checkboxShown) {
            $j('#downloadSettingsFormUseRelativeIds').show();
            $j('#downloadSettingsUseRelativeIds').prop('checked', true);
          } else {
            $j('#downloadSettingsUseRelativeIds').val('true');
          }
        } else {
          if (checkboxShown) {
            $j('#downloadSettingsFormUseRelativeIds').hide();
            $j('#downloadSettingsUseRelativeIds').prop('checked', false);
          } else {
            $j('#downloadSettingsUseRelativeIds').val('false');
          }
        }
      }
    }));
  </script>
  <bs:modalDialog formId="downloadSettingsForm"
                  title="Download settings"
                  action=""
                  closeCommand="BS.DownloadSettingsForm.close()"
                  saveCommand="false">
    <table class="runnerFormTable">
      <tr>
        <th style="width: 10em;">DSL API Version:<bs:help file="Upgrading+DSL" anchor="KotlinDSLAPIversion"/></th>
        <td>
          <select id="formatVersion" onchange="BS.DownloadSettingsForm.updateRelativeIds()"></select>
          <c:choose>
            <c:when test="${showNonPortableDSLOption}">
              <div id="downloadSettingsFormUseRelativeIds" style="margin-top: 0.5em;">
                <input type="checkbox" name="downloadSettingsUseRelativeIds" id="downloadSettingsUseRelativeIds">
                <label for="downloadSettingsUseRelativeIds">Generate portable DSL scripts<bs:help file="Kotlin+DSL" anchor="portableDSL"/></label>
              </div>
            </c:when>
            <c:otherwise>
              <input type="hidden" name="downloadSettingsUseRelativeIds" id="downloadSettingsUseRelativeIds" value="true"/>
            </c:otherwise>
          </c:choose>
        </td>
      </tr>
    </table>
    <input type="hidden" id="downloadSettingsGenUrlPrefix"/>
    <input type="hidden" id="downloadSettingsCheckUrlPrefix"/>
    <div id="downloadSettingsFormErrorsDiv">
      Cannot generate settings due to following errors:
      <ul id="downloadSettingsFormErrorsList"></ul>

      <div id="nonUniformIDs" style="display: none;">
        <bs:helpLink file="Kotlin+DSL" anchor="nonUniformIDs">Read more about IDs in portable DSL</bs:helpLink>
      </div>
    </div>
    <div class="popupSaveButtonsBlock">
      <forms:submit type="button" onclick="BS.DownloadSettingsForm.download();" label="Download"/>
      <forms:cancel onclick="BS.DownloadSettingsForm.close();"/>
      <forms:saving id="downloadSettingsFormSaving" style="float: none;"/>
    </div>
  </bs:modalDialog>
</bs:executeOnce>